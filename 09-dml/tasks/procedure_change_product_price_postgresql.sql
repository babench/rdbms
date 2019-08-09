-- procedure with transaction: use PostgreSQL 11+
-- the procedure to change the product price

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
    _client_id := (SELECT a.id
                   FROM otus.account as a
                   WHERE a.email = _client_email
                     AND a.type = 'manager'
                     AND a.deleted = false);
    IF (_client_id IS NULL OR _client_id = 0) THEN
        RAISE EXCEPTION 'available manager account % not found', _client_email;
    END IF;

    -- select product id
    _product_id := (SELECT p.id
                    FROM otus.product as p
                    WHERE p.description = _product_name);
    IF (_product_id IS NULL OR _product_id = 0) THEN
        RAISE EXCEPTION 'product % not found', _product_name;
    END IF;

    -- select product price id
    _product_price_id := (SELECT pp.id
                          FROM otus.product_price as pp
                          WHERE pp.product_id = _product_id FOR UPDATE);
    IF (_product_price_id IS NULL OR _product_price_id = 0) THEN
        RAISE EXCEPTION 'price for product % not found', _product_name;
    END IF;

    -- update product price
    UPDATE otus.product_price SET price = _next_product_price, updated_time = _now WHERE id = _product_price_id;

    -- log about product price
    INSERT INTO otus.product_price_log (product_price_id, price, modified_by, created_time)
    VALUES (_product_price_id, _next_product_price, _client_id, _now);

    COMMIT;
    RAISE NOTICE '%', 'update price: ' || _next_product_price || ' for product:' || _product_name;
END;
$$ LANGUAGE plpgsql;
