Data Manipulation Language
=======


### Goal

 - Run [Docker](https://www.docker.com) container from a database image
 - Use [Docker Compose](https://docs.docker.com/compose/) with `DDL` script
 - Open an external port to connect to the database


## Run

 - Run the PostgreSQL instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./09-dml/docker-compose.yml up
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
$ docker-compose -f ./09-dml/docker-compose.yml down
Removing otus-database ... done
Removing network 09-dml_default
```


## Documentation

[Data Manipulation Language (DML)](https://ru.wikipedia.org/wiki/Data_Manipulation_Language) - is a sublanguage of SQL to manipulate the data presented in a database

Statements:  

`INSERT` – is used to insert data into a table
  - `ON CONFLICT` can be used to specify an alternative action if data can't be inserted (`DO UPDATE` / `DO NOTHING`)
  - `RETURNING` can return specified value(s) from each row
  - since `SQL-92` supports multirow inserts
```sql
INSERT INTO phone_book (name, number)
VALUES ('John Doe', '555-1212'), ('Peter Doe', '555-2323') 
RETURNING phone_book_id;
```


`SELECT` – is used to retrieve data from the a database
  - `DISTINCT` eliminates duplicate rows from the result
  - `GROUP BY` combine into groups of rows that match on one or more values
  - `LIMIT`/`FETCH`/`OFFSET` return a subset of the result rows
  - `INTO` set selected values to variables
  - `FOR UPDATE` statement locks the selected rows against concurrent locks/updates/deletes in other transactions and child rows by PK
  - `FOR NO KEY UPDATE` similarly to the select `FOR UPDATE` but lock acquired is weaker (don't want to block the creation of child records)
  - `FOR SHARE` ...
  - `FOR KEY SHARE` ...
```sql
SELECT * FROM users AS u 
WHERE u.last_name = 'Smith' 
LIMIT 10;
```


`UPDATE` – is used to update existing data within a table
  - `WITH` allows you to specify one or more subqueries and use retrieved data for update
  - `FROM` allow using columns from other tables to appear in the `WHERE` condition and the update expressions (extension)
  - `RETURNING` returns value(s) based on each row actually updated (extension)
```sql
UPDATE users
   SET last_name = 'Ivanov'
WHERE last_name = 'Smith';


UPDATE users SET (first_name, last_name) =
   (SELECT first_name, last_name 
   FROM accounts
   WHERE accounts.id = users.sales_id);
```


`DELETE` – is used to delete records from a database table
  - `WITH` allows you to specify one or more subqueries and use retrieved data for delete
```sql
DELETE FROM trees WHERE height < 80;
```


`UPSERT` - an operation to `INSERT` a row or `UPDATE` if the row already existing
```sql
INSERT ... ON CONFLICT DO UPDATE
```


`MERGE` - statement to `INSERT` new records or `UPDATE`, or `DELETE` existing records depending on whether condition matches
  - introduced in `SQL:2003` and expanded in the `SQL:2008`
  - based on `INNER JOIN` of 2 tables: _source_ and _target_; the _target_ table is the table to be modified based on data contained within the _source_ table
  - merge condition results in one of 3 states:  `MATCHED`, `NOT MATCHED`, or `NOT MATCHED BY SOURCE`
![](https://277dfx2bm2883ohl6u2g3l59-wpengine.netdna-ssl.com/wp-content/uploads/2016/11/VISUAL-MERGE-DIAGRAM.png)

```sql
MERGE books_sales_stat AS target
USING staging_books_sales_stat AS source
     ON (target.book_id = source.book_id)
WHEN MATCHED 
     THEN UPDATE SET sales_count = source.sales_count
WHEN NOT MATCHED 
     THEN INSERT VALUES (source.book_id, source.book_name, source.sales_count)
WHEN NOT MATCHED BY SOURCE
     THEN DELETE;
```
