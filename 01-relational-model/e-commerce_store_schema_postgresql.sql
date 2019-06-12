-- DDL: use PostgreSQL

CREATE SCHEMA IF NOT EXISTS otus;

/*
id                  - surrogate identifier
description         - manufacturer's name or description
created_date        - creation timestamp in DB
updated_date        - last updated timestamp
*/
CREATE TABLE IF NOT EXISTS otus.manufacturer
(
    id           BIGSERIAL PRIMARY KEY,
    description  VARCHAR(1024) NOT NULL,
    created_date TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_date TIMESTAMPTZ
);
COMMENT ON TABLE otus.manufacturer IS 'manufacturers of products';


/*
id                  - surrogate identifier
description         - supplier's name or description
created_date        - creation timestamp in DB
updated_date        - last updated timestamp
 */
CREATE TABLE IF NOT EXISTS otus.supplier
(
    id           BIGSERIAL PRIMARY KEY,
    description  VARCHAR(1024) NOT NULL,
    created_date TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_date TIMESTAMPTZ
);
COMMENT ON TABLE otus.supplier IS 'companies responsible for the logistics';


/**
id                  - surrogate identifier
manufacturer_id     - manufacturer identifier (FK)
supplier_id         - supplier identifier (FK)
description         - product's name or description
count               - number of products
deleted             - product accessibility flag
created_time        - creation timestamp in DB
updated_time        - last updated timestamp
*/
CREATE TABLE IF NOT EXISTS otus.product
(
    id              BIGSERIAL PRIMARY KEY,
    manufacturer_id BIGSERIAL     NOT NULL REFERENCES otus.manufacturer (id),
    supplier_id     BIGSERIAL     NOT NULL REFERENCES otus.supplier (id),
    description     VARCHAR(1024) NOT NULL,
    count           int           NOT NULL,
    deleted         BOOLEAN       NOT NULL DEFAULT false,
    created_time    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_time    TIMESTAMPTZ
);
COMMENT ON TABLE otus.product IS 'products of the e-commerce store';


/*
id                  - surrogate identifier
product_id          - product identifier (FK)
property            - name of product property
description         - description of product property
comment             - common comment
created_date        - creation timestamp in DB
updated_date        - last updated timestamp
 */
CREATE TABLE IF NOT EXISTS otus.product_property
(
    id           BIGSERIAL PRIMARY KEY,
    product_id   BIGSERIAL     NOT NULL REFERENCES otus.product (id),
    property     VARCHAR(255)  NOT NULL,
    description  VARCHAR(1024) NOT NULL,
    comment      VARCHAR(1024),
    created_date TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_date TIMESTAMPTZ
);
COMMENT ON TABLE otus.product_property IS 'properties for each product';


/**
id                  - surrogate identifier
cost                - product cost
product_id          - product identifier (FK)
supplier_id         - supplier identifier (FK)
manufacturer_id     - manufacturer identifier (FK)
 */
CREATE TABLE IF NOT EXISTS otus.product_price
(
    id              BIGSERIAL PRIMARY KEY,
    price           NUMERIC(14, 2) NOT NULL,
    product_id      BIGSERIAL      NOT NULL REFERENCES otus.product (id),
    supplier_id     BIGSERIAL      NOT NULL REFERENCES otus.supplier (id),
    manufacturer_id BIGSERIAL      NOT NULL REFERENCES otus.manufacturer (id)

);
COMMENT ON TABLE otus.product_price IS 'product prices depend on manufacturers and suppliers';


/*
id                  - surrogate identifier
pwd_hash            - hash of account password
salt                - salt for account password
email               - account's e-mail aka permanent login field
phone               - account's phone number
type                - account type (0 - client, 1 - store employee, 2 - manager)
first_name          - first name
middle_name         - middle name
surname             - surname
deleted             - account accessibility flag
created_date        - creation timestamp in DB
updated_date        - last updated timestamp
birthdate           - account birthdate
 */
CREATE TABLE IF NOT EXISTS otus.account
(
    id           BIGSERIAL PRIMARY KEY,
    pwd_hash     VARCHAR(255) NOT NULL,
    salt         VARCHAR(255) NOT NULL,
    email        VARCHAR(50)  NOT NULL,
    phone        VARCHAR(15),
    type         SMALLINT     NOT NULL,
    first_name   VARCHAR(100),
    middle_name  VARCHAR(100),
    surname      VARCHAR(100),
    deleted      BOOLEAN      NOT NULL DEFAULT false,
    created_date TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_date TIMESTAMPTZ,
    birthdate    TIMESTAMPTZ
);
COMMENT ON TABLE otus.account IS 'e-commerce store accounts';


/*
id                  - surrogate identifier
owner_id            - client identifier id, owner of the order (FK)
created_date        - creation timestamp in DB
scheduled_date      - scheduled delivery date and time
delivery_date      - actual delivery date and time
*/
CREATE TABLE IF NOT EXISTS otus.order
(
    id             BIGSERIAL PRIMARY KEY,
    owner_id       BIGSERIAL   NOT NULL REFERENCES otus.account (id),
    created_date   TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheduled_date TIMESTAMPTZ NOT NULL,
    delivered_date TIMESTAMPTZ
);
COMMENT ON TABLE otus.order IS 'clients orders';


/*
id                  - surrogate identifier
order_id            - oder identifier (FK)
product_id          - product identifier (FK)
comment             - clarifications or wishes to the order
address             - delivery address
count               - number of products in the order
total_price         - final price after calculations for concrete client
created_date        - creation timestamp in DB
updated_date        - last updated timestamp
*/
CREATE TABLE IF NOT EXISTS otus.order_details
(
    id           BIGSERIAL PRIMARY KEY,
    order_id     BIGSERIAL      NOT NULL REFERENCES otus.order (id),
    product_id   BIGSERIAL      NOT NULL REFERENCES otus.product (id),
    comment      VARCHAR(1024),
    address      VARCHAR(255)   NOT NULL,
    count        INT            NOT NULL DEFAULT 1,
    total_price  NUMERIC(14, 2) NOT NULL,
    created_date TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_date TIMESTAMPTZ
);
COMMENT ON TABLE otus.order_details IS 'detailed information by each order';

/**
  order status from item in a store to user delivery
 */
CREATE TYPE otus.order_status AS ENUM (
    'not_paid', 'paid', 'canceled',
    'packed', 'shipped', 'returned',
    'lost', 'delivered');

/*
id                  - surrogate identifier
order_id            - oder identifier (FK)
modified_by         - account identifier changed the order status (FK)
status              - order status
created_date        - creation timestamp in DB
 */
CREATE TABLE IF NOT EXISTS otus.order_log
(
    id           BIGSERIAL PRIMARY KEY,
    order_id     BIGSERIAL         NOT NULL REFERENCES otus.order (id),
    modified_by  BIGSERIAL         NOT NULL REFERENCES otus.account (id),
    status       otus.order_status NOT NULL,
    created_date TIMESTAMPTZ       NOT NULL DEFAULT now()
);
COMMENT ON TABLE otus.order_log IS 'orders changelog';
