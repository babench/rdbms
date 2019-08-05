Data Definition Language
=======


### Goal

 - Run [Docker](https://www.docker.com) container from a database image
 - Use [Docker Compose](https://docs.docker.com/compose/) with `DDL` script
 - Open an external port to connect to the database


## Run

 - Run the PostgreSQL instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./08-ddl/docker-compose.yml up
$ docker exec -ti otus-database bash
bash-4.4# psql -U store_user -d store
psql (11.4)
Type "help" for help.
```
 - Show database schema of the e-commerce store
   - 1st part: `manufacturer`, `supplier`, `product`, `product_property`, `product_price`, `product_price_log`
   - 2nd part: `account` with enum `account_type`
   - 3rd part: `order` with enum `order_status`, `order_details`, `order_log`
```sql
store=# \dt+ otus.
                                                  List of relations
 Schema |       Name        | Type  |   Owner    |    Size    |                     Description
--------+-------------------+-------+------------+------------+------------------------------------------------------
 otus   | account           | table | store_user | 16 kB      | e-commerce store accounts
 otus   | manufacturer      | table | store_user | 16 kB      | manufacturers of products
 otus   | order             | table | store_user | 0 bytes    | clients orders
 otus   | order_details     | table | store_user | 8192 bytes | detailed information by each order
 otus   | order_log         | table | store_user | 0 bytes    | orders changelog
 otus   | product           | table | store_user | 16 kB      | products of the e-commerce store
 otus   | product_price     | table | store_user | 8192 bytes | product prices depend on manufacturers and suppliers
 otus   | product_price_log | table | store_user | 8192 bytes | product price changelog
 otus   | product_property  | table | store_user | 16 kB      | properties for each product
 otus   | supplier          | table | store_user | 16 kB      | companies responsible for the logistics
(10 rows)
```


## Stop

 * The app is terminated by the response to a user interrupt such as typing `^C` (Ctrl + C) or a system-wide event of a shutdown
```bash
...
^CGracefully stopping... (press Ctrl+C again to force)
Killing otus-database  ... done
```

 * Remove containers and networks
```bash
$ docker-compose -f ./08-ddl/docker-compose.yml down
Removing otus-database ... done
Removing network 08-ddl_default
```


## Documentation

[Data Definition Language (DDL)](https://en.wikipedia.org/wiki/Data_definition_language) - is a sublanguage of SQL to define/modify data structures, especially database schemas

 - All statements are atomic operations
 - Statement commits open transaction in `MS SQL`, `MySQL`, `Oracle` and it is the reason don't mix transactions with `DML` and `DDL` statements
```sql
-- MySQL
mysql> show tables;
Empty set (0.00 sec)

mysql> START TRANSACTION;
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE test_table (id INT PRIMARY KEY, created_time TIMESTAMP DEFAULT now());
Query OK, 0 rows affected (0.02 sec)

mysql> ROLLBACK;
Query OK, 0 rows affected (0.00 sec)

mysql> show tables;
+-----------------+
| Tables_in_store |
+-----------------+
| test_table      |
+-----------------+
1 row in set (0.00 sec)

```
 - Statement doesn't commit open transaction in `PostgreSQL`
```sql
-- PostgreSQL
db=# \dt+
Did not find any relations.

db=# BEGIN;
BEGIN
db=# CREATE TABLE test_table (id INT PRIMARY KEY, created_time TIMESTAMPTZ DEFAULT now());
CREATE TABLE

db=# \dt+
                        List of relations
 Schema |    Name    | Type  |   Owner    |  Size   | Description
--------+------------+-------+------------+---------+-------------
 public | test_table | table | store_user | 0 bytes |
(1 row)

db=# ROLLBACK;
ROLLBACK
db=# \dt+
Did not find any relations.
```


---
Statements  

`CREATE` - creates objects: schemas, databases, tables, views, indexes, custom data types, collations, functions or procedures, and assertions
```sql
CREATE TABLE employees (
    id            INT            PRIMARY KEY,
    first_name    VARCHAR(100)   NOT NULL,
    last_name     VARCHAR(100)   NOT NULL,
    dateofbirth   DATE           NOT NULL
);
```


`ALTER` - change the properties of objects inside of RDBMS; lock on the table  
performance hint:
 - add nullable column
 - update rows at several transactions
 - set default and not nullable value
```sql
ALTER TABLE employees ADD COLUMN email VARCHAR(255);
```


`DROP` - removes objects from the database: table, index, view, and others
```sql
DROP TABLE employees;
```


---
`Tablespaces` - location in the file system where the files representing database objects can be stored
 - several tablespaces could store objects of the same database
 - a new additional tablespace can be placed on a very fast, highly available disk to store main indexes with frequent usage
 - a new additional tablespace can be created on a different partition to extend existing cluster space that could be not enough at this time until the system can be reconfigured

```sql
-- PostgreSQL
CREATE TABLESPACE fastspace LOCATION '/ssd1/postgresql/data';
CREATE TABLE IF NOT EXISTS foo(i int) TABLESPACE fastspace;

-- or use default tablespace
SET default_tablespace = fastspace;
CREATE TABLE IF NOT EXISTS foo(i int);
```


---
`Table inheritance` - is a feature defined in `SQL:1999`, allows to extract a common set of columns into a parent table, children tables define additional fields
  - `PostgreSQL` inheritance is not SQL-compliant
  - `MySQL`, `Oracle` and `MS SQL` does not support it

 - In `PostgreSQL`, a table can inherit from [0..*) tables
 - `INSERT` always inserts into exactly the table specified
 - `SELECT`, `UPDATE`, `DELETE` typically include child tables in a result, unless explicitly specified `ONLY` notation
 - All `CHECK` constraints and `NOT NULL` constraints are automatically inherited from parent to child tables unless explicitly specified `NO INHERIT`
 - Inheritance could be defined at the time of creating a child table or later by `ALTER TABLE`
 - Use `CASCADE` option if you need to drop the columns of the parent table
 - Indexes (including unique) and foreign key constraints only apply to single tables

```sql
CREATE TABLE cities (
    name            TEXT,
    population      INT,
    altitude        INT
);

-- inherits all the columns from the parent table, cities
CREATE TABLE capitals (
    state           CHAR(2)
) INHERITS (cities);

...

-- all rows
SELECT name, population
    FROM cities
    WHERE population > 600000;

     name      | population 
---------------+----------
 Las Vegas     |    648224
 Washington    |    672228
 New York City |   8537673


-- only cities table rows
SELECT name, population
    FROM ONLY cities
    WHERE population > 600000;

   name    | population
-----------+----------
 Las Vegas |    648224
```

Benefits:
 - querying the master table, the query references all rows of master and children tables
 - changes performed on the master table are propagated to the children (ALTER TABLE, UPDATE)
   - if a child table has a column with the same name and different type, the operation will fail


---
`Partitioning` is a splitting what is logically one large table into smaller physical pieces

 - Good solution if a table is very large and the size exceeds the physical memory of the database server
 - Partitioning is used for sharding data by several servers
 - Partition table could be divided into sub-partitions with another form of partitioning (parent table -> range partitioning by date -> list subpartition by region)
 - Available for `MySQL`, `Oracle`, `PostgreSQL` and `MS SQL`
   - `MySQL` has a limit for 8192 partitions

   
 - `PostgreSQL 9.x` allows table partitioning via `table inheritance`
   - each partition is a `child` table of a single `parent` table with explicit _constraint_ and _index_ by key columns (date for example)
   - create a trigger `BEFORE INSERT` and trigger function dispatch insert statements and spread to each child table
   - parent table is empty and exists only to represent the whole data set
   - each partition maps to its own filegroup (one or more data files)
 - Since `PostgreSQL 10.x` and `11.x` partitioning has been simplified by integration into the database engine:
   - no need a trigger to override insertions into the parent table to the corresponding partition table
   - have instructions to attach/detach partitions from the parent table
   - have a sub-partitions and new system table `pg_partitioned_table`
   - `VACUUM` and `ANALYZE` work for all partitions from the parent table
   - rows move automatically between partitions by `UPDATE`
   - partition tables shouldn't have additional columns

   
Partitioning there are 3 forms:
 - Range Partitioning
   - defined by a key column or set of columns, with no overlap between the ranges of values
   - examples: [January..February], [March..April], [May..June], [July..August], ...

 - List Partitioning
   - defined by lists of key explicitly assign by partitions
   - example: East sales region (New York, Florida), West sales region (California, Oregon) and others...

 - Hash Partitioning
   - a hash algorithm is used to distribute data equally among multiple a predetermined number of partitions
   - it is usually used where we can’t use RANGE key, and column contains a lot of distinct value


Example:
```sql
-- create as a partitioned table with `range` form
CREATE TABLE measurement (
    city_id         int not null,
    logdate         date not null,
    peaktemp        int,
    unitsales       int
) PARTITION BY RANGE (logdate);


-- create partition tables specified by date ranges
CREATE TABLE measurement_y2006m02 PARTITION OF measurement
    FOR VALUES FROM ('2006-02-01') TO ('2006-03-01');

CREATE TABLE measurement_y2006m03 PARTITION OF measurement
    FOR VALUES FROM ('2006-03-01') TO ('2006-04-01');
...

-- create an index on the key column
CREATE INDEX ON measurement (logdate);
```


Benefits:
 - the relative speedup of queries that requires only portions of large data sets (the optimizer eliminates searching in partitions that don't have relevant information)
 - faster data load (reduced index size fits in memory)
 - faster deletion of old data can be accomplished by:
   - removing the whole partitions (DROP TABLE is far faster than a bulk operation)
   - limited rows in certain partitions (reduce the VACUUM overhead)
 - some partitions could be migrated to cheaper and slower storages if they are archive data or seldom-used


---
`Temporary table` is used and visible for session-level only

 - could be used to store variable values or loads data from external services
 - tables are automatically dropped at the end of a session or current transaction (optionally) (MySQL, MS SQL, PostgreSQL)
 - action for a commit in session: `DELETE ROWS`, `PRESERVE ROWS`

```sql
CREATE TEMP TABLE customers(id INT);
```

------------------------------------------------------
[Data control language (DDL)](https://en.wikipedia.org/wiki/Data_control_language) - is a sublanguage of SQL used to control access to data stored in a database


Statements:
 - `GRANT` to allow specified users to perform specified tasks
 - `REVOKE` it removes the user accessibility to the database object



Links:  
https://www.postgresql.org/docs/11/manage-ag-tablespaces.html  
https://www.postgresql.org/docs/11/ddl-partitioning.html  
https://dev.mysql.com/doc/refman/8.0/en/partitioning.html  
