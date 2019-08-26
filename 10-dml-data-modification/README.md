Data Manipulation Language: data modification
=======


### Goal

 - Run [Docker](https://www.docker.com) container from a database image
 - Use [Docker Compose](https://docs.docker.com/compose/) with `DDL` script
 - Open an external port to connect to the database



## Run

 - Run the MySQL instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./10-dml-data-modification/docker-compose.yml up
Creating network "10-dml-data-modification_default" with the default driver
Creating otus-database ... done
Attaching to otus-database
...

$ docker exec -ti otus-database bash
root@f5e040d19d55:/# mysql -u voip_user -p
Enter password:
...
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| voip               |
+--------------------+
2 rows in set (0.01 sec)

mysql> use voip;
Database changed
```

 - `CDR` is the table of phone calls (information)
```sql
-- CDR.CID - surrogate ID of the table
-- CDR.CALLID - a phone call identifier
-- CDR.SRC_IP - an IP address of a phone call from an operator
-- CDR.SETUP_TIME - a phone call date and time
mysql> select c.CID, c.CALLID, c.HOST, c.SRC_IP, c.DST_IP, c.SRC_NUMBER_BILL, c.DST_NUMBER_BILL, c.SETUP_TIME from CDR as c where c.src_ip is not null limit 10;
+-----------+----------------------------------+----------------+--------------+---------------+-----------------+-----------------+---------------------+
| CID       | CALLID                           | HOST           | SRC_IP       | DST_IP        | SRC_NUMBER_BILL | DST_NUMBER_BILL | SETUP_TIME          |
+-----------+----------------------------------+----------------+--------------+---------------+-----------------+-----------------+---------------------+
| 830385127 | 3A3AD8B2EE8211E786D62C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 17114131655     | 48790805006     | 2018-01-01 00:02:26 |
| 830385128 | 3AB1D7B4EE8211E786E02C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 11300603811     | 48576970511     | 2018-01-01 00:02:26 |
| 830385129 | 3AAE8AF0EE8211E786E02C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 13372816037     | 48796639328     | 2018-01-01 00:02:27 |
...
```

 - `oper_ip` is the table of registered IP addresses
```sql
-- oper_ip.id - surrogate ID of the table
-- oper_ip.op_id - operator identifier
-- oper_ip.ip_op - an IP address of a phone call from an operator
mysql> select o.id, o.op_id, o.ip_op, o.gateway_id from oper_ip as o limit 10;
+------+-------+---------------+--------------------------+
| id   | op_id | ip_op         | gateway_id               |
+------+-------+---------------+--------------------------+
| 1904 |   209 | 188.40.92.145 | Melliton_GW_2            |
| 1905 |   209 | 85.29.138.100 | Melliton_GW_21           |
| 2290 |   216 | 85.10.192.13  | QuickDial_GW_271         |
| 2800 |    14 | 46.249.44.230 | TeleXchange_System_GW_15 |
...
```

 - Show database schema of the e-commerce store
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

 - The app is terminated by the response to a user interrupt such as typing `^C` (Ctrl + C) or a system-wide event of a shutdown
```bash
...
^CGracefully stopping... (press Ctrl+C again to force)
Killing otus-database  ... done
```

 - Remove containers and networks
```bash
$ docker-compose -f ./09-dml/docker-compose.yml down
Removing otus-database ... done
Removing network 09-dml_default
```


## Documentation

[Data Manipulation Language (DML)](https://ru.wikipedia.org/wiki/Data_Manipulation_Language) - is a sublanguage of SQL to manipulate the data presented in a database

Data could be stored in one table only and simple queries have only accessed one table at a time.
Join query - is a query that accesses multiple rows of the same or different tables at one time.
`JOIN` - is a join operation in relational algebra combines columns from 2 tables to 1 result table
  - result table includes columns from both source tables (clutch)
  - rows from 2 tables could clutch together in many ways and the way depends on the _type_ of _JOIN_
  - need to use _JOIN_ sequentially if you want to clutch more than 2 tables
  - `WHERE` clause will apply to the resulting table after _JOIN_

ANSI-standard `SQL` specifies 5 types of JOIN: 
  - `INNER JOIN`,
  - `LEFT OUTER JOIN`,
  - `RIGHT OUTER JOIN`, 
  - `FULL OUTER JOIN`
  - `CROSS JOIN`

What type of _JOIN_ do you need to use? Business examples:
  - select all _sales_ that were in the past and _stock balance_  ==>  `INNER JOIN` because don't need a `NULL` values for sold products
  - select all cases of _goods delivery_ by couriers that without active tasks now  ==>  `CROSS JOIN` because we need to show all cases for each courier
  - select all _goods_ in the stock and _sales log_ by each of them if they were  ==>  `LEFT OUTER JOIN` because we need all goods and info about sales


---
`CROSS JOIN` - cartesian product, it produces a result table which combines each row from the first table with each row from the second table
  - combinatorial algorithm ueses `cartesian product` to iterate through all objects in a loop
```sql
SELECT *
FROM employee, department;
```
![](https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Cartesian_Product_qtl1.svg/440px-Cartesian_Product_qtl1.svg.png)


---
`FULL JOIN` - result set combines the effect of applying both `left` and `right outer join`s for a two tables
  - will have `NULL` values for every column of the table that lacks a matching row
  - will have rows with all populated columns
  - could be applied to reports
  - it is not a `CROSS JOIN`

```
SELECT *
FROM employee as e FULL OUTER JOIN department as d
  ON e.department_id = d.department_id;
```

![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/SQL_Join_-_05b_A_Full_Join_B.svg/440px-SQL_Join_-_05b_A_Full_Join_B.svg.png)


---
`LEFT JOIN` - result set of tables A and B always contains all rows of the "left" table (A) and matched rows of the "right" table (B)
  - will have `NULL` values for every column of the table (B) that lacks a matching with a row of the table (A)

```sql
SELECT *
FROM employee as e LEFT OUTER JOIN department as d 
  ON e.department_id = d.department_id;
```

![](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/SQL_Join_-_01_A_Left_Join_B.svg/440px-SQL_Join_-_01_A_Left_Join_B.svg.png)


---
`RIGHT JOIN` - result set of tables A and B always contains all rows of the "right" table (B) and matched rows of the "left" table (A)
  - will have `NULL` values for every column of the table (A) that lacks a matching with a row of the table (B)

```sql
SELECT *
FROM employee as e RIGHT OUTER JOIN department as d 
  ON e.department_id = d.department_id;
```

![](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/SQL_Join_-_03_A_Right_Join_B.svg/440px-SQL_Join_-_03_A_Right_Join_B.svg.png)


---
`INNER JOIN` - result set of tables (A) and (B) always have only matching non-NULL column values from 2 tables

```sql
SELECT *
FROM employee as e INNER JOIN department as d
   ON e.department_id = d.department_id;
```

![](https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/SQL_Join_-_07_A_Inner_Join_B.svg/440px-SQL_Join_-_07_A_Inner_Join_B.svg.png)


Best practices:
  - use `INNER JOIN` if you can than others
  - use `LEFT JOIN` instead of `RIGHT JOIN` if you can
  - add indexes on join columns


---

operator `BETWEEN` and ranges:
```sql
SELECT *
FROM item as t
WHERE t.price BETWEEN 10 AND 100;

-- equal to range [10..100]
SELECT *
FROM item as t
WHERE t.price >= 10 AND t.price <= 100;
```


operators direct comparison and ANY/IN
```sql
SELECT *
FROM item as t
WHERE t.price = 10 OR t.price = 100 OR t.price = 150;

-- equal to ANY with values
SELECT *
FROM item as t
WHERE t.price = ANY (SELECT price FROM price_list);

-- equal to IN with values
SELECT *
FROM item as t
WHERE t.price IN (SELECT price FROM price_list);
```


operators direct comparison and ALL/NOT IN
```sql
SELECT *
FROM item as t
WHERE t.price != 10 AND t.price != 100 AND t.price != 150;

-- equal to ALL with values
SELECT *
FROM item as t
WHERE t.price != ALL (SELECT price FROM price_list);

-- equal to NOT IN with values
SELECT *
FROM item as t
WHERE t.price NOT IN (SELECT price FROM price_list);
```


`EXISTS` vs `COUNT(*) > 0`
```sql
-- better performance
IF EXISTS(SELECT 1 FROM actor WHERE actor_id = :id limit 1) THEN
     PRINT 'yes'
     ELSE
     PRINT 'no'
END IF;

-- don't do with COUNT
IF (SELECT COUNT(*) FROM actor WHERE actor_id = :id) > 0 THEN
     PRINT 'yes'
     ELSE
     PRINT 'no'
END IF;
```

Links:  
 - ...  
