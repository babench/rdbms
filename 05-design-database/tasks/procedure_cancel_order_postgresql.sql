-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE cancel_store_order(BIGINT, BIGINT) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _canceled_status   otus.order_status := 'canceled';
    _selected_order_id BIGINT;
    _product_count     INT;
    _product_id        BIGINT;
    _scheduled_time    TIMESTAMPTZ;
    _now               TIMESTAMPTZ;
BEGIN
    _now := now();

    -- select order
    SELECT r.id, r.scheduled_time
    INTO _selected_order_id, _scheduled_time
    FROM otus.order as r
    WHERE r.id = _order_id
      AND status IN ('not_paid', 'paid', 'packed', 'shipped') FOR UPDATE;
    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found in states: not_paid, paid, packed, shipped', _order_id;
    END IF;

    -- return product(s)
    SELECT od.count, od.product_id
    INTO _product_count, _product_id
    FROM otus.order_details as od
    WHERE od.order_id = _order_id;
    UPDATE otus.product SET count = (count + _product_count), updated_time = _now WHERE id = _product_id;

    -- cancel order
    UPDATE otus.order SET status = _canceled_status, updated_time = _now WHERE id = _selected_order_id;

    -- log about canceled order
    INSERT INTO otus.order_log (order_id, modified_by, status, created_time, scheduled_time)
    VALUES (_selected_order_id, _modified_by, _canceled_status, _now, _scheduled_time);

    COMMIT;
    RAISE NOTICE 'order id % canceled', _selected_order_id;
END;
$$ LANGUAGE plpgsql;
