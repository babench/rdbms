-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE return_store_order(BIGINT, BIGINT) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _returned_status   otus.order_status := 'returned';
    _selected_order_id BIGINT;
    _product_count     INT;
    _product_id        BIGINT;
    _scheduled_time    TIMESTAMPTZ;
    _now               TIMESTAMPTZ;
BEGIN
    _now := now();

    -- select order
    select r.id, r.scheduled_time
    into _selected_order_id, _scheduled_time
    from otus.order as r
    where r.id = _order_id
      and status in ('delivered', 'lost') FOR UPDATE;
    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found in states: delivered, lost', _order_id;
    END IF;

    -- return product(s)
    select od.count, od.product_id
    into _product_count, _product_id
    from otus.order_details as od
    where od.order_id = _order_id;
    update otus.product set count = (count + _product_count), updated_time = _now where id = _product_id;

    -- return order
    update otus.order set status = _returned_status, updated_time = _now where id = _selected_order_id;

    -- log about canceled order
    INSERT INTO otus.order_log (order_id, modified_by, status, created_time, scheduled_time)
    VALUES (_selected_order_id, _modified_by, _returned_status, _now, _scheduled_time);

    COMMIT;
    RAISE NOTICE 'order id % returned', _selected_order_id;
END ;
$$ LANGUAGE plpgsql;
