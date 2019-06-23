-- function: use PostgreSQL

CREATE OR REPLACE PROCEDURE next_store_order(VARCHAR(512), INT, VARCHAR(50)) AS
$$
DECLARE
    _product_name ALIAS FOR $1;
    _order_product_count ALIAS FOR $2;
    _client_email ALIAS FOR $3;
    _product_id        BIGINT;
    _client_id         BIGINT;
    _order_id          BIGINT;
    _product_price     NUMERIC;
    _schedule_interval interval = '3 day';
BEGIN
    -- select product id
    _product_id := (select p.id
                    from otus.product as p
                    where p.description = _product_name and p.count >= _order_product_count FOR UPDATE);
    IF (_product_id IS NULL OR _product_id = 0) THEN
        RAISE EXCEPTION 'product % not found', _product_name;
    END IF;
    RAISE NOTICE '%', 'product_id = ' || _product_id || ', name = ' || _product_name;

    -- select product price
    _product_price := (select p.price from otus.product_price as p where p.product_id = _product_id);
    IF (_product_price IS NULL OR _product_price = 0.0) THEN
        RAISE EXCEPTION 'price for product % not found', _product_id;
    END IF;
    RAISE NOTICE 'product_price = %', _product_price;

    -- select account id of client
    _client_id := (select a.id
                   from otus.account as a
                   where a.email = _client_email and a.type = 'client' and a.deleted = false);
    IF (_client_id IS NULL OR _client_id = 0) THEN
        RAISE EXCEPTION 'client account % not found', _client_email;
    END IF;
    RAISE NOTICE '%', 'account_id = ' || _client_id || ', e-mail = ' || _client_email;
    RAISE NOTICE 'schedule_interval = %', _schedule_interval;

    -- book products
    UPDATE otus.product set count = count - _order_product_count where id = _product_id;

    -- make a new order
    INSERT INTO otus.order (owner_id, product_id, status, created_time, scheduled_time)
    VALUES (_client_id, _product_id, 'not_paid', now(), now() + _schedule_interval) RETURNING id INTO _order_id;
    RAISE NOTICE 'order_id = %, status = not_paid', _order_id;

    INSERT INTO otus.order_details (order_id, product_id, comment, address, count, total_price, created_time)
    VALUES (_order_id, _product_id, 'comment', 'address', _order_product_count, _product_price, now());

    INSERT INTO otus.order_log (order_id, modified_by, status, created_time)
    VALUES (_order_id, _client_id, 'not_paid', now());

END;
$$ LANGUAGE plpgsql;
