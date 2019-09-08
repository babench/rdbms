Data Manipulation Language: data modification
=======


### Goal

 - Run [Docker](https://www.docker.com) container with `voip` database
 - Task: calculate a phone call price
 - Tables for calculating the price of a phone call: `CDR`, `oper_ip`, `SITE`, `RATES` and `DEST_CODE`
 - `CDR` is the table of phone calls from an operator
```sql
-- CDR.cid - surrogate ID of the table
-- CDR.callid - a phone call identifier
-- CDR.src_ip - an IP address of a phone call from an operator (*)
-- CDR.setup_time - a phone call date and time
mysql> select c.cid, c.callid, c.host, c.src_ip, c.dst_ip, c.setup_time
       from CDR as c where c.src_ip is not null limit 10;
+-----------+----------------------------------+----------------+--------------+---------------+---------------------+
| cid       | callid                           | host           | src_ip (*)   | dst_ip        | setup_time          |
+-----------+----------------------------------+----------------+--------------+---------------+---------------------+
| 830385127 | 3A3AD8B2EE8211E786D62C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 2018-01-01 00:02:26 |
| 830385128 | 3AB1D7B4EE8211E786E02C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 2018-01-01 00:02:26 |
| 830385129 | 3AAE8AF0EE8211E786E02C59E59A3C25 | 217.118.24.215 | 195.219.39.9 | 104.155.12.12 | 2018-01-01 00:02:27 |
...
```

 - `oper_ip` is the table of registered IP addresses
```sql
-- oper_ip.id - surrogate ID of the table
-- oper_ip.op_id - operator identifier (*)
-- oper_ip.ip_op - IP address of a phone call from an operator (*)
mysql> select o.id, o.op_id, o.ip_op, o.gateway_id from oper_ip as o limit 10;
+------+----------+---------------+--------------------------+
| id   | op_id (*)| ip_op (*)     | gateway_id               |
+------+----------+---------------+--------------------------+
| 1904 |   209    | 188.40.92.145 | Melliton_GW_2            |
| 1905 |   209    | 85.29.138.100 | Melliton_GW_21           |
| 2290 |   216    | 85.10.192.13  | QuickDial_GW_271         |
...
```

 - `SITE` is the table of operator sites (departments)
```sql
-- SITE.id - operator identifier (*)
-- SITE.sitename - name of site
-- SITE.rate_o - rate number of an operator at assignment time (*)
mysql> select s.id, s.sitename, s.rate_o from SITE as s limit 10;
+-------+--------------------+-----------+
| id (*)| sitename           | rate_o (*)|
+-------+--------------------+-----------+
|   1   | Unknown IP         |      0    |
|   4   | QuickDial          |    700    |
| 209   | Melliton 777#      |    934    |
...
```

 - `RATES` is the table of phone call rates
```sql
-- RATES.code_id - code of rate number (*)
-- RATES.rate_id - rate number of an operator at assignment time (*)
-- RATES.price - phone call price (!)
mysql> select r.code_id, r.rate_id, r.price from RATES as r limit 10;
+------------+------------+----------+
| code_id (*)| rate_id (*)| price (!)|
+------------+------------+----------+
|  188990    |     850    | 0.039600 |
|   99788    |     850    | 0.023700 |
|  188991    |     850    | 0.032300 |
...
```

 - `DEST_CODE` is the table of code descriptions for a phone calls (should be found max code for a price)
```sql
-- DEST_CODE.DEST_ID - code of rate number (*)
-- DEST_CODE.CODE - code description
mysql> select * from DEST_CODE limit 10;
+------------+----------+
| DEST_ID (*)| CODE (*) |
+------------+----------+
|       1    |    0     |
|       1    |    1     |
|       1    |    2     |
...
```



### Implementation

Overview and preparing for the task
 - We have the table of IP-addresses with duplicates phone calls (not unique IP-addresses); for example let's have a look to the query
```sql
mysql> select o.id, o.op_id, o.ip_op, o.gateway_id from oper_ip as o where o.ip_op = '188.40.92.145';
+------+-------+---------------+---------------+
| id   | op_id | ip_op         | gateway_id    |
+------+-------+---------------+---------------+
|  634 |    94 | 188.40.92.145 | Melliton_GW_2 |
| 1904 |   209 | 188.40.92.145 | Melliton_GW_2 |
| 1645 |    94 | 188.40.92.145 | Melliton_GW_2 |
| 2859 |    94 | 188.40.92.145 | Melliton_GW_2 |
| 2715 |   209 | 188.40.92.145 | Melliton_GW_2 |
+------+-------+---------------+---------------+
5 rows in set (0.00 sec)
```

 - Total count of IP-address
```sql
mysql> select count(o.ip_op) from oper_ip as o;
+----------------+
| count(o.ip_op) |
+----------------+
|            796 |
+----------------+
1 row in set (0.00 sec)
```

 - Unique count of IP-address
```sql
mysql> select count(distinct o.ip_op) from oper_ip as o;
+-------------------------+
| count(distinct o.ip_op) |
+-------------------------+
|                     186 |
+-------------------------+
1 row in set (0.00 sec)
```

 - Let's make a temp table without duplicates of IP-address
```sql
mysql> create temporary table oper_ip_temp (id int, op_id int, ip_op varchar(20), gateway_id varchar(50));

mysql> insert into oper_ip_temp (id, op_id, ip_op, gateway_id) 
    select o1.id, o1.op_id, o1.ip_op, o1.gateway_id 
    from oper_ip as o1 
    where not exists (select * from oper_ip as o2 where o1.ip_op = o2.ip_op and o1.id > o2.id);
Query OK, 186 rows affected (0.02 sec)
Records: 186  Duplicates: 0  Warnings: 0

mysql> select count(ip_op) from oper_ip_temp;
+--------------+
| count(ip_op) |
+--------------+
|          186 |
+--------------+
1 row in set (0.00 sec)
```

---
Explanation step by step to find a call price
 - Select 1 arbitrary row with IP-address of a phone call `(src_ip)`
```sql
mysql> select host, callid, elapsed_time, src_ip from CDR limit 1;
+----------------+----------------------------------+--------------+--------------+
| host           | callid                           | elapsed_time | src_ip       |
+----------------+----------------------------------+--------------+--------------+
| 217.118.24.215 | 3A3AD8B2EE8211E786D62C59E59A3C25 |            7 | 195.219.39.9 |
+----------------+----------------------------------+--------------+--------------+
1 row in set (0.00 sec)
```

 - Find an ID of the operator `(op_id)` whose make the phone call on a previous step `(src_ip)`
```sql
mysql> select oper_ip_temp.op_id, cdr_table.src_ip, oper_ip_temp.ip_op, cdr_table.elapsed_time
    from (select host, callid, elapsed_time, src_ip from CDR limit 1) as cdr_table
    inner join oper_ip_temp on cdr_table.src_ip = oper_ip_temp.ip_op;
+-------+--------------+--------------+--------------+
| op_id | src_ip       | ip_op        | elapsed_time |
+-------+--------------+--------------+--------------+
|   143 | 195.219.39.9 | 195.219.39.9 |            7 |
+-------+--------------+--------------+--------------+
1 row in set (0.00 sec)
```

 - Find the phone call rate `(rate_o)` by operator ID `(op_id)`
```sql
mysql> select oper_ip_temp.op_id, cdr_table.src_ip, oper_ip_temp.ip_op, cdr_table.elapsed_time, s.rate_o
    from (select host, callid, elapsed_time, src_ip from CDR limit 1) as cdr_table
    inner join oper_ip_temp on cdr_table.src_ip = oper_ip_temp.ip_op
    inner join SITE as s on oper_ip_temp.op_id = s.id;
+-------+--------------+--------------+--------------+--------+
| op_id | src_ip       | ip_op        | elapsed_time | rate_o |
+-------+--------------+--------------+--------------+--------+
|   143 | 195.219.39.9 | 195.219.39.9 |            7 |    853 |
+-------+--------------+--------------+--------------+--------+
1 row in set (0.00 sec)
```

- Link the phone call rate `(rate_o)` with rates table `(rate_id)` and codes table (code_id)
```sql
mysql> select oper_ip_temp.op_id, cdr_table.src_ip, oper_ip_temp.ip_op, cdr_table.elapsed_time, s.rate_o, r.rate_id, r.price, r.code_id, dc.dest_id, dc.code
    from (select host, callid, elapsed_time, src_ip from CDR limit 1) as cdr_table
    inner join oper_ip_temp on cdr_table.src_ip = oper_ip_temp.ip_op
    inner join SITE as s on oper_ip_temp.op_id = s.id
    inner join RATES as r on s.rate_o = r.rate_id
    inner join DEST_CODE as dc on dc.dest_id = r.code_id;
+-------+--------------+--------------+--------------+--------+---------+----------+---------+---------+------+
| op_id | src_ip       | ip_op        | elapsed_time | rate_o | rate_id | price    | code_id | dest_id | code |
+-------+--------------+--------------+--------------+--------+---------+----------+---------+---------+------+
|   143 | 195.219.39.9 | 195.219.39.9 |            7 |    853 |     853 | 0.011000 |   91609 |   91609 | 1    |
|   143 | 195.219.39.9 | 195.219.39.9 |            7 |    853 |     853 | 0.005400 |   91609 |   91609 | 1    |
|   143 | 195.219.39.9 | 195.219.39.9 |            7 |    853 |     853 | 0.003800 |   91615 |   91615 | 1302 |
    ...   ...
+-------+--------------+--------------+--------------+--------+---------+----------+---------+---------+------+
15482 rows in set (0.15 sec)
```

 - First, select the max phone call price `(RATES.price)` by each code `(DEST_CODE.code)`; second, select the max code and its price is `the price of a phone call`
```sql
mysql> select CAST(dc.code as UNSIGNED) as code, max(r.price)
    from (select host, callid, elapsed_time, src_ip from CDR limit 1) as cdr_table
    inner join oper_ip_temp on cdr_table.src_ip = oper_ip_temp.ip_op
    inner join SITE as s on oper_ip_temp.op_id = s.id
    inner join RATES as r on s.rate_o = r.rate_id
    inner join DEST_CODE as dc on dc.dest_id = r.code_id
    group by code
    order by code DESC
    limit 1;
+-------------+--------------+
| code        | max(r.price) |
+-------------+--------------+
| 78482946949 |     0.006200 |
+-------------+--------------+
1 row in set, 1 warning (0.16 sec)
```



## Run

 - Extract the database snapshot file from 7-Zip archive
```sql
$ 7z x -o./10-dml-data-modification ./10-dml-data-modification/voip.sql.7z
7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
...

Everything is Ok

Size:       1194110062
Compressed: 74360535

$ ls -lah ./10-dml-data-modification
total 2488200
drwxr-xr-x   6 dima  staff   192B  8 сен 21:25 .
drwxr-xr-x  18 dima  staff   576B  8 сен 21:20 ..
-rw-r--r--   1 dima  staff    16K  8 сен 21:25 README.md
-rw-r--r--   1 dima  staff   332B  8 сен 21:11 docker-compose.yml
-rw-r--r--   1 dima  staff   1,1G 25 авг 17:26 voip.sql
-rw-r--r--   1 dima  staff    71M  8 сен 21:11 voip.sql.7z
```

 - Run the `MySQL` instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./10-dml-data-modification/docker-compose.yml up
Creating network "10-dml-data-modification_default" with the default driver
Creating otus-database ... done
Attaching to otus-database
...

$ docker exec -ti otus-database bash
root@f5e040d19d55:/# mysql -u voip_user -D voip -p
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

mysql> show tables;
+------------------------+
| Tables_in_voip         |
+------------------------+
| ACLOSE_STAT            |
| ACTIONS                |
...
| user_agents            |
| user_info              |
+------------------------+
71 rows in set (0.01 sec)
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
$ docker-compose -f ./10-dml-data-modification/docker-compose.yml down
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
