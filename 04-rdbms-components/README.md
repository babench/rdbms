Data types
=======

### Run

 - The

### Stop

 * The

## Documentation

---
Users and roles

 - databases are complex and expensive product; direct access to its internal functionality and objects poses a security risk
 - a user is a name defined in the database that can connect to and access objects
 - a schema is a named collection of objects (tables, views, clusters, procedures, indexes)
 - schemas and users help database administrators manage database security
 - a role defines user's access rights to work with database objects
 - in the SQL access control model creator of each object becomes its owner
 - the object owner could be authorized by the user authID or self role name
 - each SQL connection is associated with authID

```sql
create user <username> with password '<password>'

grand connect on database <dbName> to <username>;
grand select on table <tableName> to <username>;
```


---
OLTP (Online Transaction Processing) - organizing the real-time database work with a large flow of small-time transactions and responds immediately to user requests
 - payment acceptance
 - sale of goods in shops
 - update an account data
OLTP features: high throughput and are insert/update intensive


OLAP (Online Analytical Processing) - organizing the database characterized by long-time transactions and much more complex queries to huge amounts of data for the purpose of business intelligence or reporting
 - report of total sales of each department in each month
 - identify top-saling books
 - count classes with A++ marks by half a year
OLAP features: availability, speed, concurrency and recoverability


---
`Schema` - is essentially a namespace: it contains named objects (tables, data types, functions, and operators) whose names can duplicate those of other objects existing in other schemas
 - schema name uses as a prefix for each full object name into the schema
 - unqualified object name creates the object in the current schema

```sql
CREATE SCHEMA IF NOT EXISTS <schema_name>;
-- or for user
CREATE SCHEMA IF NOT EXISTS <schema_name> AUTHORIZATION <user_name>;
```


---
`Database connecntion` is expensive operation:
  - open socket
  - make tcp connection
  - parse string sql statement
  - authentication
  - create client session (dedicated - one session per connection, shared - several sessions per connection, DRCP)
  - execute sql command
  - close client connection

 - each SQL connection is a new process for the host OS
 - connection `pooling` let you reduce database-related overhead don't create physical connections on each time that dragging performance down
```sql
get connection ---> [connection pool -> pull exists or create new] ---> execute sql statement ---> [close connection -> push to pool]
```


---
`Index` - is an object (data structure) that can improves the speed of data retrieval operations but each insert/update/delete takes time to normalized the index data structure

 - can be computed from the values of one or more columns (composite index) of the table row
 - 1 select often use only 1 index to retrieve data
 - `non-clustered`: the data is present in arbitrary order, but the logical ordering is specified by the index
   - one or more per table
   - use additional disk space
   - uses in MS SQL, MySQL
   - PostgreSQL clusters the table by one-time operation
 - `clustered`: alters the data block into a certain distinct order to match the index
   - only one per table
   - not use additional disk space


---
`Constraints` on columns and tables give you control over the data that comes into the tables
 - `check constraints` is generic constraint type, allows you to specify that the value in a certain column(s) must satisfy a truth-value expression
 - `not-null constraints` specifies that a column must not assume the `null` value
 - `unique constraints` ensure that the data contained in a column(s) is unique among all the rows in the table
   - automatically create a unique B-tree index on the column(s)
   - field(s) allows having a `null` value
- `primary key` indicates that a column(s) can be used as a unique identifier for rows in the table
  - field(s) shouldn't have `null` value
  - automatically create a unique B-tree index on the column(s)
- `foreign keys` specifies that the values in a column(s) must match the values appearing in some row of another table
- `exclusion` ...


---
`Trigger` is a specification that the database should automatically execute a particular function whenever a certain type of operation is performed. 
 - can be attached to tables, views, and foreign tables
 - can be execute before/after any `INSERT`, `UPDATE`, or `DELETE` operation
 - can be execute instead of `INSERT`, `UPDATE`, or `DELETE` operations (no in MySQL)
 - can also fire for `TRUNCATE` statements
 - have access to an `old` and `new` row set
 - works in the same transaction that the sql statement
 - compiled code and execution plan

```sql
create trigger <trigger_name> after insert
               on <table_name> for each row execute procedure <procedure_name>();
```


---
View - is not physically materialized result table of a query
 - alias for a query
 - helps to hide the complexity of the original query

Materialized view - physically materialized result table of a query
 - remembers the query used to initialize the view, so that it can be refreshed later upon demand
 - can be auto-updatable


---
Links:
 https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html
 https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html
 https://www.postgresql.org/docs/11/sql-cluster.html
 https://www.postgresql.org/docs/11/sql-createindex.html
 https://www.postgresql.org/docs/11/ddl-constraints.html
 https://www.postgresql.org/docs/11/trigger-definition.html
 https://habr.com/ru/post/141767/
