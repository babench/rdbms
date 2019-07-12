-- procedure with transaction: use PostgreSQL 11+

CREATE OR REPLACE PROCEDURE change_product_price(VARCHAR(512), VARCHAR(50), NUMERIC(14, 2)) AS
$$
DECLARE
    _product_name ALIAS FOR $1;
    _client_email ALIAS FOR $2;
    _next_product_price ALIAS FOR $3;
    _client_id        BIGINT;
    _product_id       BIGINT;
    _product_price_id BIGINT;
    _now              TIMESTAMPTZ;
BEGIN
    _now := now();
    IF (_next_product_price > 0) THEN
        -- nothing to do
    ELSE
        RAISE EXCEPTION 'next product price: % should be positive', _next_product_price;
    END IF;

    -- select manager account id
    _client_id := (select a.id
                   from otus.account as a
                   where a.email = _client_email
                     and a.type = 'manager'
                     and a.deleted = false);
    IF (_client_id IS NULL OR _client_id = 0) THEN
        RAISE EXCEPTION 'available manager account % not found', _client_email;
    END IF;

    -- select product id
    _product_id := (select p.id
                    from otus.product as p
                    where p.description = _product_name);
    IF (_product_id IS NULL OR _product_id = 0) THEN
        RAISE EXCEPTION 'product % not found', _product_name;
    END IF;

    -- select and update product price id
    _product_price_id := (select pp.id
                          from otus.product_price as pp
                          where pp.product_id = _product_id FOR UPDATE);
    IF (_product_price_id IS NULL OR _product_price_id = 0) THEN
        RAISE EXCEPTION 'price for product % not found', _product_name;
    END IF;

    UPDATE otus.product_price SET price = _next_product_price, updated_time = _now where id = _product_price_id;

    -- log about product price
    INSERT INTO otus.product_price_log (product_price_id, price, modified_by, created_time)
    VALUES (_product_price_id, _next_product_price, _client_id, _now);

    COMMIT;
    RAISE NOTICE '%', 'update price: ' || _next_product_price || ' for product:' || _product_name;
END;
$$ LANGUAGE plpgsql;
