-- DML: use PostgreSQL

-- account: client
INSERT INTO otus.account (id, pwd_hash, phone, email, type, first_name, surname, deleted, birthdate)
VALUES (1, 'pwd_hash1', '+71021110022', 'dmitriy@invalid.test', 'client', 'dmitriy', 'shishmakov', false, '1960-06-03');

-- account: store_employee
INSERT INTO otus.account (id, pwd_hash, phone, email, type, first_name, surname, deleted, birthdate)
VALUES (2, 'pwd_hash2', '+71090001122', 'vladimir@invalid.test', 'store_employee', 'vladimir', 'mironov', false,
        '1980-06-03');

-- account: manager
INSERT INTO otus.account (id, pwd_hash, phone, email, type, first_name, surname, deleted, birthdate)
VALUES (3, 'pwd_hash3', '+71090104422', 'ingvar@invalid.test', 'manager', 'ingvar', 'shishmakov', false, '1991-06-03');

-- manufacturer 1
INSERT INTO otus.manufacturer (id, tag, description)
VALUES (1, 'tag_m1', 'manufacturer 1');

-- supplier 1
INSERT INTO otus.supplier (id, tag, description)
VALUES (1, 'tag_s1', 'supplier 1');

-- product 1 + properties + price
INSERT INTO otus.product (id, tag, manufacturer_id, supplier_id, description, count, deleted)
VALUES (1, 'tag_prod1', 1, 1, 'product 1', 100, false);
INSERT INTO otus.product_property (product_id, property_name, property_desc, comment)
VALUES (1, 'property 1', 'property description product 1', 'comment');
INSERT INTO otus.product_property (product_id, property_name, property_desc, comment)
VALUES (1, 'property 2', 'property description product 1', 'comment');
INSERT INTO otus.product_price (product_id, supplier_id, manufacturer_id, price)
VALUES (1, 1, 1, 110.0);

-- product 2 + properties + price
INSERT INTO otus.product (id, tag, manufacturer_id, supplier_id, description, count, deleted)
VALUES (2, 'tag_prod2', 1, 1, 'product 2', 50, false);
INSERT INTO otus.product_property (product_id, property_name, property_desc, comment)
VALUES (2, 'property 1', 'property description product 2', 'comment');
INSERT INTO otus.product_property (product_id, property_name, property_desc, comment)
VALUES (2, 'property 2', 'property description product 2', 'comment');
INSERT INTO otus.product_price (product_id, supplier_id, manufacturer_id, price)
VALUES (2, 1, 1, 55.0);
