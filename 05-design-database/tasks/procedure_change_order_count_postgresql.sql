-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE change_order_count(BIGINT, BIGINT, INT) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _next_order_count ALIAS FOR $3;
    _selected_order_id         BIGINT;
    _selected_order_details_id BIGINT;
    _selected_product_id       BIGINT;
    _product_price             NUMERIC;
    _old_order_count           INT;
    _delta_count               INT;
    _now                       TIMESTAMPTZ;
BEGIN
    _now := now();
    IF (_next_order_count > 0) THEN
        -- nothing to do
    ELSE
        RAISE EXCEPTION 'next product count: % should be positive', _next_order_count;
    END IF;

    -- check order state
    _selected_order_id := (SELECT o.id
                           FROM otus.order AS o
                           WHERE o.id = _order_id
                             AND o.status = 'not_paid');
    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found in state not paid', _order_id;
    END IF;

    -- select order details info
    SELECT o.id, o.count, o.product_id
    INTO _selected_order_details_id, _old_order_count, _selected_product_id
    FROM otus.order_details AS od
    WHERE od.id = _selected_order_id FOR UPDATE;
    IF (_selected_order_details_id IS NULL OR _selected_order_details_id = 0) THEN
        RAISE EXCEPTION 'details for order id % not found', _selected_order_id;
    END IF;

    -- check delta count
    _delta_count := _next_order_count - _old_order_count;
    IF (_delta_count = 0) THEN
        RAISE EXCEPTION '%', 'change next product count: ' || _next_order_count || 'in order: ' || _selected_order_id;
    END IF;

    -- select product price
    _product_price := (SELECT p.price FROM otus.product_price as p WHERE p.product_id = _selected_product_id);
    IF (_product_price IS NULL OR _product_price = 0.0) THEN
        RAISE EXCEPTION 'price for product % not found', _product_id;
    END IF;

    -- update product and order
    -- ...

    COMMIT;
    RAISE NOTICE '%', 'update price: ' || _next_product_price || ' for product:' || _product_name;
END ;
$$ LANGUAGE plpgsql;
