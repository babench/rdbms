-- DDL: use PostgreSQL

CREATE SCHEMA IF NOT EXISTS otus;

/**
  order status from item in a store to user delivery
 */
CREATE TYPE otus.order_status AS ENUM (
  'not_paid', 'paid', 'canceled',
  'packed', 'shipped', 'returned',
  'lost', 'delivered');

/**
  order status from item in a store to user delivery
 */
CREATE TYPE otus.account_type AS ENUM ('client', 'store_employee', 'manager');


CREATE TABLE IF NOT EXISTS otus.manufacturer
(
  id           BIGSERIAL PRIMARY KEY,
  tag          VARCHAR(15)   NOT NULL,
  description  VARCHAR(1024) NOT NULL,
  created_time TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_time TIMESTAMPTZ
);
COMMENT ON TABLE otus.manufacturer IS 'manufacturers of products';
COMMENT ON COLUMN otus.manufacturer.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.manufacturer.tag IS 'manufacturer''s short name for searching';
COMMENT ON COLUMN otus.manufacturer.description IS 'manufacturer''s name or description; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.manufacturer.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.manufacturer.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';

CREATE INDEX IF NOT EXISTS manufacturer_tag_idx ON otus.manufacturer (tag);
COMMENT ON INDEX otus.manufacturer_tag_idx IS 'tag is metadata for searching by manufacturer';


CREATE TABLE IF NOT EXISTS otus.supplier
(
  id           BIGSERIAL PRIMARY KEY,
  tag          VARCHAR(15)   NOT NULL,
  description  VARCHAR(1024) NOT NULL,
  created_time TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_time TIMESTAMPTZ
);
COMMENT ON TABLE otus.supplier IS 'companies responsible for the logistics';
COMMENT ON COLUMN otus.supplier.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.supplier.tag IS 'supplier''s short name for searching';
COMMENT ON COLUMN otus.supplier.description IS 'supplier''s name or description; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.supplier.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.supplier.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';

CREATE INDEX IF NOT EXISTS supplier_tag_idx ON otus.supplier (tag);
COMMENT ON INDEX otus.supplier_tag_idx IS 'tag is metadata for searching by supplier';


CREATE TABLE IF NOT EXISTS otus.product
(
  id              BIGSERIAL PRIMARY KEY,
  manufacturer_id BIGINT        NOT NULL REFERENCES otus.manufacturer (id),
  supplier_id     BIGINT        NOT NULL REFERENCES otus.supplier (id),
  tag             VARCHAR(15)   NOT NULL,
  description     VARCHAR(1024) NOT NULL,
  count           INT           NOT NULL CHECK (count >= 0),
  deleted         BOOLEAN       NOT NULL DEFAULT false,
  created_time    TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_time    TIMESTAMPTZ
);
COMMENT ON TABLE otus.product IS 'products of the e-commerce store';
COMMENT ON COLUMN otus.product.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.product.manufacturer_id IS 'manufacturer identifier (FK)';
COMMENT ON COLUMN otus.product.supplier_id IS 'supplier identifier (FK)';
COMMENT ON COLUMN otus.product.tag IS 'product''s short name for searching';
COMMENT ON COLUMN otus.product.description IS 'product''s name or description; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.product.count IS 'number of products; integer is the common choice for numeric type, as it offers the best balance between range, storage size, and performance';
COMMENT ON COLUMN otus.product.deleted IS 'product accessibility flag; true and false are the possible values';
COMMENT ON COLUMN otus.product.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.product.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';

CREATE INDEX IF NOT EXISTS product_manufacturer_id_supplier_id_idx ON otus.product (manufacturer_id, supplier_id);
CREATE INDEX IF NOT EXISTS product_tag_idx ON otus.product (tag);
CREATE INDEX IF NOT EXISTS product_deleted_idx ON otus.product (deleted, count) where deleted = false and count > 0;
COMMENT ON INDEX otus.product_manufacturer_id_supplier_id_idx IS 'need to search for products by manufacturers and suppliers';
COMMENT ON INDEX otus.product_tag_idx IS 'tag is metadata for searching by supplier';
COMMENT ON INDEX otus.product_deleted_idx IS 'search for products currently available for purchases';


CREATE TABLE IF NOT EXISTS otus.product_property
(
  id            BIGSERIAL PRIMARY KEY,
  product_id    BIGINT        NOT NULL REFERENCES otus.product (id),
  property_name VARCHAR(255)  NOT NULL,
  property_desc VARCHAR(1024) NOT NULL,
  comment       VARCHAR(1024),
  created_time  TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_time  TIMESTAMPTZ
);
COMMENT ON TABLE otus.product_property IS 'properties for each product';
COMMENT ON COLUMN otus.product_property.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.product_property.product_id IS 'product identifier (FK)';
COMMENT ON COLUMN otus.product_property.property_name IS 'name of product property; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.product_property.property_desc IS 'description of product property; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.product_property.comment IS 'common comment; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.product_property.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.product_property.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';

CREATE INDEX IF NOT EXISTS product_product_id_idx ON otus.product_property (product_id);
COMMENT ON INDEX otus.product_product_id_idx IS 'helps to select exact properties for the products';


CREATE TABLE IF NOT EXISTS otus.product_price
(
  id              BIGSERIAL PRIMARY KEY,
  price           NUMERIC(14, 2) NOT NULL CHECK (price > 0),
  product_id      BIGINT         NOT NULL REFERENCES otus.product (id),
  supplier_id     BIGINT         NOT NULL REFERENCES otus.supplier (id),
  manufacturer_id BIGINT         NOT NULL REFERENCES otus.manufacturer (id)

);
COMMENT ON TABLE otus.product_price IS 'product prices depend on manufacturers and suppliers';
COMMENT ON COLUMN otus.product_price.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.product_price.price IS 'product cost; numeric is especially recommended type for storing monetary amounts';
COMMENT ON COLUMN otus.product_price.product_id IS 'product identifier (FK)';
COMMENT ON COLUMN otus.product_price.supplier_id IS 'supplier identifier (FK)';
COMMENT ON COLUMN otus.product_price.manufacturer_id IS 'manufacturer identifier (FK)';

CREATE INDEX IF NOT EXISTS product_price_price_idx ON otus.product_price (price);
CREATE INDEX IF NOT EXISTS product_price_product_id_idx ON otus.product_price (product_id);
COMMENT ON INDEX otus.product_price_price_idx IS 'helps to get ranges of product prices';
COMMENT ON INDEX otus.product_price_product_id_idx IS 'get product price';


CREATE TABLE IF NOT EXISTS otus.account
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
COMMENT ON TABLE otus.account IS 'e-commerce store accounts';
COMMENT ON COLUMN otus.account.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.account.pwd_hash IS 'hash of account password; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.email IS 'account''s e-mail aka permanent login field; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.phone IS 'account''s phone number; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.type IS 'account type; enum type comprises a static and ordered set of values that helps to escape errors';
COMMENT ON COLUMN otus.account.first_name IS 'first name; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.middle_name IS 'middle name; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.surname IS 'surname; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.account.deleted IS 'account accessibility flag; true and false are the possible values';
COMMENT ON COLUMN otus.account.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.account.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';
COMMENT ON COLUMN otus.account.birthdate IS 'account birthdate; only date in the year';

CREATE UNIQUE INDEX IF NOT EXISTS account_email_idx ON otus.account (email);
CREATE INDEX IF NOT EXISTS account_deleted_type_idx ON otus.account (deleted, type) where deleted = false;
COMMENT ON INDEX otus.account_email_idx IS 'e-mail should be unique for all accounts; this is user login';
COMMENT ON INDEX otus.account_deleted_type_idx IS 'search among available accounts';


CREATE TABLE IF NOT EXISTS otus.order
(
  id             BIGSERIAL PRIMARY KEY,
  owner_id       BIGINT            NOT NULL REFERENCES otus.account (id),
  product_id     BIGINT            NOT NULL REFERENCES otus.product (id),
  status         otus.order_status NOT NULL,
  created_time   TIMESTAMPTZ       NOT NULL DEFAULT now(),
  scheduled_time TIMESTAMPTZ       NOT NULL,
  delivered_time TIMESTAMPTZ
);
COMMENT ON TABLE otus.order IS 'clients orders';
COMMENT ON COLUMN otus.order.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.order.owner_id IS 'client identifier id, owner of the order (FK)';
COMMENT ON COLUMN otus.order.product_id IS 'product identifier (FK)';
COMMENT ON COLUMN otus.order.status IS 'order status; enum type comprises a static and ordered set of values that helps to escape errors';
COMMENT ON COLUMN otus.order.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.order.scheduled_time IS 'scheduled delivery date and time; helps to define a date and time in a concrete time zone';
COMMENT ON COLUMN otus.order.delivered_time IS 'actual delivery date and time; helps to define a date and time in a concrete time zone';

CREATE INDEX IF NOT EXISTS oder_product_id_owner_id_status_idx ON otus.order (product_id, owner_id, status);
CREATE INDEX IF NOT EXISTS oder_created_time_scheduled_time_idx ON otus.order (created_time, scheduled_time);
COMMENT ON INDEX otus.oder_product_id_owner_id_status_idx IS 'filter orders by product, buyer and order status';
COMMENT ON INDEX otus.oder_created_time_scheduled_time_idx IS 'sort and filter orders by creation time';


CREATE TABLE IF NOT EXISTS otus.order_details
(
  id           BIGSERIAL PRIMARY KEY,
  order_id     BIGINT         NOT NULL REFERENCES otus.order (id),
  product_id   BIGINT         NOT NULL REFERENCES otus.product (id),
  comment      VARCHAR(1024),
  address      VARCHAR(255)   NOT NULL,
  count        INT            NOT NULL DEFAULT 1 CHECK (count > 0),
  total_price  NUMERIC(14, 2) NOT NULL,
  created_time TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_time TIMESTAMPTZ
);
COMMENT ON TABLE otus.order_details IS 'detailed information by each order';
COMMENT ON COLUMN otus.order_details.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.order_details.order_id IS 'order identifier (FK)';
COMMENT ON COLUMN otus.order_details.product_id IS 'product identifier (FK)';
COMMENT ON COLUMN otus.order_details.comment IS 'clarifications or wishes to the order; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.order_details.address IS 'delivery address; varchar is a variable-length character type with a chance to set a limit size of data';
COMMENT ON COLUMN otus.order_details.count IS 'number of products; integer is the common choice for numeric type, as it offers the best balance between range, storage size, and performance';
COMMENT ON COLUMN otus.order_details.total_price IS 'final price after calculations for concrete client; numeric is especially recommended type for storing monetary amounts';
COMMENT ON COLUMN otus.order_details.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';
COMMENT ON COLUMN otus.order_details.updated_time IS 'last updated timestamp; it is a timestamp with a time zone defines an exact moment when the data had updated';

CREATE INDEX IF NOT EXISTS order_details_order_id_idx ON otus.order_details (order_id);
COMMENT ON INDEX otus.order_details_order_id_idx IS 'select detail info for order';


CREATE TABLE IF NOT EXISTS otus.order_log
(
  id           BIGSERIAL PRIMARY KEY,
  order_id     BIGINT            NOT NULL REFERENCES otus.order (id),
  modified_by  BIGINT            NOT NULL REFERENCES otus.account (id),
  status       otus.order_status NOT NULL,
  created_time TIMESTAMPTZ       NOT NULL DEFAULT now()
);
COMMENT ON TABLE otus.order_log IS 'orders changelog';
COMMENT ON COLUMN otus.order_log.id IS 'surrogate identifier; auto sequence of the big integer is a good choice for a long time e-commerce store';
COMMENT ON COLUMN otus.order_log.order_id IS 'oder identifier (FK)';
COMMENT ON COLUMN otus.order_log.modified_by IS 'account identifier changed the order status (FK)';
COMMENT ON COLUMN otus.order_log.status IS 'order status; enum type comprises a static and ordered set of values that helps to escape errors';
COMMENT ON COLUMN otus.order_log.created_time IS 'creation timestamp in DB; it is a timestamp with a time zone defines an exact moment when the data had appeared';

CREATE INDEX IF NOT EXISTS order_log_order_id_idx ON otus.order_log (order_id);
COMMENT ON INDEX otus.order_log_order_id_idx IS 'select log records for order';
