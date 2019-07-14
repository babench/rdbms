-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE change_order_count(BIGINT, BIGINT, INT) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _next_order_count ALIAS FOR $3;
    _old_order_count           INT;
    _available_product_count   INT;
    _selected_order_id         BIGINT;
    _selected_order_details_id BIGINT;
    _selected_product_id       BIGINT;
    _product_price             NUMERIC;
    _delta_count               INT;
    _selected_scheduled_time   TIMESTAMPTZ;
    _now                       TIMESTAMPTZ;
    _selected_delivered_time   TIMESTAMPTZ;
    _not_paid_status           otus.order_status := 'not_paid';
BEGIN
    _now := now();
    IF (_next_order_count > 0) THEN
        -- nothing to do
    ELSE
        RAISE EXCEPTION 'next product count: % should be positive', _next_order_count;
    END IF;

    -- check order state
    SELECT o.id, o.scheduled_time, o.delivered_time
    INTO _selected_order_id, _selected_scheduled_time, _selected_delivered_time
    FROM otus.order AS o
    WHERE o.id = _order_id
      AND o.status = _not_paid_status;
    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found; you could change product counts only for a not paid order', _order_id;
    END IF;

    -- select order details info
    SELECT od.id, od.count, od.product_id
    INTO _selected_order_details_id, _old_order_count, _selected_product_id
    FROM otus.order_details AS od
    WHERE od.id = _selected_order_id FOR UPDATE;
    IF (_selected_order_details_id IS NULL OR _selected_order_details_id = 0) THEN
        RAISE EXCEPTION 'details for order id % not found', _selected_order_id;
    END IF;

    -- check current and next amount of product in order
    _delta_count := _next_order_count - _old_order_count;
    IF (_delta_count = 0) THEN
        RAISE EXCEPTION '%', 'the same product count: ' || _next_order_count ||
                             ' in order: ' || _selected_order_id || ' ; choose another count';
    END IF;

    -- select product price
    _product_price := (SELECT p.price FROM otus.product_price AS p WHERE p.product_id = _selected_product_id);
    IF (_product_price IS NULL OR _product_price = 0.0) THEN
        RAISE EXCEPTION 'price for product % not found', _product_id;
    END IF;

    -- select and check available amount of product
    _available_product_count := (SELECT p.count
                                 FROM otus.product AS p
                                 WHERE p.id = _selected_product_id
                                   AND deleted = false FOR UPDATE);
    IF (_available_product_count IS NULL) THEN
        RAISE EXCEPTION 'product id: % not found or not available', _selected_product_id;
    END IF;
    IF ((_available_product_count - _delta_count) >= 0) THEN
        -- nothing to do
    ELSE
        RAISE EXCEPTION '%', 'available amount: ' || _available_product_count ||
                             ' of product id: ' || _selected_product_id || ' is not enough';
    END IF;

    -- update fields 'count' for product and order
    UPDATE otus.order_details
    SET count        = _next_order_count,
        total_price  = _product_price * _next_order_count,
        updated_time = _now
    WHERE order_id = _selected_order_id;
    UPDATE otus.product
    SET count        = count - _delta_count,
        updated_time = _now
    WHERE id = _selected_product_id;

    -- log about changing product count in the order
    INSERT INTO otus.order_log (order_id, modified_by, count, status, created_time, scheduled_time, delivered_time)
    VALUES (_selected_order_id, _modified_by, _next_order_count, _not_paid_status, _now, _selected_scheduled_time,
            _selected_delivered_time);

    COMMIT;
    RAISE NOTICE '%', 'update count: ' || _next_order_count || ' for order id:' || _selected_order_id;
END ;
$$ LANGUAGE plpgsql;
