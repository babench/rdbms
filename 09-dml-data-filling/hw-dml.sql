-- hw 09-dml-changing data

-- use temp table for home work only
CREATE TEMP TABLE IF NOT EXISTS account_temp
(
    id           BIGSERIAL PRIMARY KEY,
    pwd_hash     VARCHAR(255)      NOT NULL,
    email        VARCHAR(50)       NOT NULL,
    phone        VARCHAR(15),
    type         otus.account_type NOT NULL,
    first_name   VARCHAR(100),
    middle_name  VARCHAR(100),
    surname      VARCHAR(100),
    deleted      BOOLEAN           NOT NULL DEFAULT false,
    created_time TIMESTAMPTZ       NOT NULL DEFAULT now(),
    updated_time TIMESTAMPTZ,
    birthdate    DATE
);

-- simple insert temp values
INSERT INTO account_temp (id, pwd_hash, phone, email, type, first_name, surname, deleted, birthdate)
VALUES (4, 'pwd_hash4', '+71903410902', 'alexey@invalid.test', 'client', 'alexey', 'bogoliubov', false, '1980-11-03'),
       (5, 'pwd_hash5', '+74177001140', 'anton@invalid.test', 'store_employee', 'anton', 'mironov', false,
        '1981-12-04'),
       (6, 'pwd_hash6', '+71090104422', 'igor@invalid.test', 'manager', 'igor', 'shishmakov', false, '1991-06-03');

-- insert by select (use temp table)
INSERT INTO otus.account (id, pwd_hash, phone, email, type, first_name, surname, deleted, birthdate)
SELECT act.id,
       act.pwd_hash,
       act.phone,
       act.email,
       act.type,
       act.first_name,
       act.surname,
       act.deleted,
       act.birthdate
FROM account_temp as act;

-- simple update statement
UPDATE otus.account
SET phone        = '+76160061600',
    updated_time = now()
WHERE id = 1;

-- update by join (use FROM for PostgreSQL)
UPDATE otus.account as ac
SET first_name   = act.first_name,
    updated_time = now()
FROM account_temp as act
WHERE ac.phone = act.phone;

-- delete all inserted data (from temp table)
DELETE
FROM otus.account
WHERE id in (4, 5, 6);

-- the procedure to make an order to buy a product in an e-commerce store
call next_store_order('product 1', 22, 'dmitriy@invalid.test');
