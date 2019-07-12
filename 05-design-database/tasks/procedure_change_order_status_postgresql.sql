-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE change_store_order_status(BIGINT, BIGINT, otus.order_status) AS
$$
DECLARE
    _order_id ALIAS FOR $1;
    _modified_by ALIAS FOR $2;
    _next_state ALIAS FOR $3;
    _selected_status   VARCHAR(8);
    _selected_order_id BIGINT;
    _scheduled_time    TIMESTAMPTZ;
    _delivered_time    TIMESTAMPTZ;
    _now               TIMESTAMPTZ;
    _need_change_state BOOL := false;
BEGIN
    _now := now();

    -- select order
    SELECT r.id, r.scheduled_time, r.delivered_time, r.status
    INTO _selected_order_id, _scheduled_time, _delivered_time, _selected_status
    FROM otus.order AS r
    WHERE r.id = _order_id
      AND status in ('not_paid', 'paid', 'packed', 'shipped', 'delivered', 'lost') FOR UPDATE;

    IF (_selected_order_id IS NULL OR _selected_order_id = 0) THEN
        RAISE EXCEPTION 'order id % not found in states: not_paid, paid, packed, shipped', _order_id;
    END IF;

    -- check order state
    CASE _selected_status
        -- not_paid --> paid
        WHEN 'not_paid' THEN
            IF (_next_state = 'paid') THEN
                _need_change_state := TRUE;
            ELSIF (_next_state = 'canceled') THEN
                CALL cancel_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'order id % next state should be paid before', _order_id;
            END IF;
        -- paid --> ( canceled | packed)
        WHEN 'paid' THEN
            IF (_next_state = 'packed') THEN
                _need_change_state := TRUE;
            ELSIF (_next_state = 'canceled') THEN
                CALL cancel_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'order id % next state should be canceled or packed', _order_id;
            END IF;

        -- packed --> ( canceled | shipped | lost)
        WHEN 'packed' THEN
            IF (_next_state = 'shipped' or _next_state = 'lost') THEN
                _need_change_state := TRUE;
            ELSIF (_next_state = 'canceled') THEN
                CALL cancel_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'order id % next state should be canceled, shipped or lost', _order_id;
            END IF;

        -- shipped --> ( canceled | delivered | lost)
        WHEN 'shipped' THEN
            IF (_next_state = 'delivered' or _next_state = 'lost') THEN
                _need_change_state := TRUE;
            ELSIF (_next_state = 'canceled') THEN
                CALL cancel_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'order id % next state should be canceled, delivered or lost', _order_id;
            END IF;

        -- delivered --> returned
        WHEN 'delivered' THEN
            IF (_next_state = 'returned') THEN
                call return_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'invoke special function for state returned only';
            END IF;

        -- lost --> returned
        WHEN 'lost' THEN
            IF (_next_state = 'returned') THEN
                call return_store_order(_selected_order_id, _modified_by);
            ELSE
                RAISE EXCEPTION 'products could be found and returned only; invoke special function';
            END IF;

        ELSE
            RAISE EXCEPTION 'state % undefine', _selected_status;
        END CASE;

    IF (_need_change_state = TRUE) THEN
        -- change order state
        UPDATE otus.order SET status = _next_state, updated_time = _now WHERE id = _selected_order_id;
        -- log about changing status
        INSERT INTO otus.order_log (order_id, modified_by, status, created_time, scheduled_time, delivered_time)
        VALUES (_selected_order_id, _modified_by, _next_state, _now, _scheduled_time, _delivered_time);
    END IF;

    COMMIT;
    RAISE NOTICE 'order id %', _order_id || ' moved from ' || _selected_status || ' to ' || _next_state;
END;
$$ LANGUAGE plpgsql;
