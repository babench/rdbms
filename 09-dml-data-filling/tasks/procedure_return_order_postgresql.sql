-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE return_store_order(BIGINT, BIGINT) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _returned_status      otus.order_status := 'returned';
    _selected_order_id    BIGINT;
    _selected_order_count INT;
    _next_order_count     INT               = 0;
    _next_order_price     NUMERIC(14, 2)    = 0.0;
    _product_id           BIGINT;
    _scheduled_time       TIMESTAMPTZ;
    _delivered_time       TIMESTAMPTZ;
    _now                  TIMESTAMPTZ;
BEGIN
    _now := now();

    -- select order
    SELECT r.id, r.scheduled_time, r.delivered_time
    INTO _selected_order_id, _scheduled_time, _delivered_time
    FROM otus.order AS r
    WHERE r.id = _order_id
      AND status in ('delivered', 'lost') FOR UPDATE;
    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found in states: delivered, lost', _order_id;
    END IF;

    -- return product(s)
    SELECT od.count, od.product_id
    INTO _selected_order_count, _product_id
    FROM otus.order_details AS od
    WHERE od.order_id = _order_id FOR UPDATE;
    UPDATE otus.product SET count = (count + _selected_order_count), updated_time = _now WHERE id = _product_id;

    -- return order
    UPDATE otus.order SET status = _returned_status, updated_time = _now WHERE id = _selected_order_id;
    UPDATE otus.order_details
    SET count       = _next_order_count,
        total_price = _next_order_price
    where order_id = _selected_order_id;

    -- log about returned order
    INSERT INTO otus.order_log (order_id, modified_by, count, status, created_time, scheduled_time, delivered_time)
    VALUES (_selected_order_id, _modified_by, _next_order_count, _returned_status, _now, _scheduled_time,
            _delivered_time);

    COMMIT;
    RAISE NOTICE 'order id % returned', _selected_order_id;
END ;
$$ LANGUAGE plpgsql;
