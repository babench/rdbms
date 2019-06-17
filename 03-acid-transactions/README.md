Data types
=======

## Run
...


## Stop
...


## Documentation

[OLTP](https://en.wikipedia.org/wiki/Online_transaction_processing) (Online Transaction Processing) - organizing the database works with a large flow of small-time transactions and responds immediately to user requests

[Transaction](https://en.wikipedia.org/wiki/Database_transaction) is an atomic unit of work and may consist of several operations performed within an RDBMS by rule all-or-nothing (commit or rollback)
 - N statements with `autocommit=true` -> N transactions
 - N statements with `autocommit=false` + commit -> 1 transaction

[Savepoint](https://en.wikipedia.org/wiki/Savepoint) is an SQL statement divides a transaction on logical points: 
 - help to control the statements in a transaction in a more granular fashion through
 - allow to selectively discard parts of the transaction, while committing the rest


```sql
-- PostgreSQL
BEGIN;
  UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
  SAVEPOINT my_savepoint;
  
  UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
  -- oops ... forget that and use Wally's account
  ROLLBACK TO my_savepoint;
  
  UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;


-- MySQL
START TRANSACTION;
  UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
  SAVEPOINT my_savepoint;

  UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
  -- oops ... forget that and use Wally's account
  ROLLBACK TO my_savepoint;

  UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;
```


---
[ACID](https://en.wikipedia.org/wiki/ACID) - properties describe the major guarantees of the transaction paradigm even in the event of errors, power failures, etc.

 - `Atomicity` guarantees that each transaction is treated as a single "unit", which either succeeds completely, or fails completely
 - `Consistency` ensures that a transaction can only bring the database from one valid state to another, prevents database corruption after an illegal transaction
 - `Isolation` levels ensure that transactions can execute concurrently and don't interfere with each other to read, write data (_read uncommitted_, _read committed_, _repeatable reads_, _serializable_)
 - `Durability` guarantees that once a transaction has been committed, it will remain committed even in the case of a system failure


Isolation, read phenomena:
 - lost updates (several concurrent transactions can read an old value from one field and update concurrently it and never mind the previous one)
 - dirty reads (one transaction may read not-yet-committed changes made by other transactions)
 - non-repeatable reads (reading several times one row in the transaction can return different values if it changed by a concurrent transaction)
 - phantom reads (in one transaction can select unequal row count if new rows could be added or removed by other transactions)


Isolation levels:
 - read uncommitted
   - `dirty reads`, `lost updates`, `non-repeatable` and `phantom reads` are allowed
 - read committed
   - `lost updates`, `non-repeatable` and `phantom reads` can occur
   - keeps write locks until the transaction ends but read locks are released at the statement ends
   - default for `Oracle`, `MS SQL`, `PostgreSQL`
 - repeatable reads
   - `phantom reads` can occur
   - keeps read and write locks until the transaction ends
   - default for `MySQL`
 - serializable
   - requires that read and write locks and range-locks of touched tuples to be released at the end of the transaction
   - requires related transactions to be executed sequentially


---
Block levels:
 - database lock
 - table lock
 - page lock
 - block lock (`Oracle` use 8Kb)
 - row lock (`PostgreSQL`, `MySQL`)


Block types:
 - eXclusive lock
   - only one holder
   - for Select/Update/Insert/Delete
 - shared lock
   - multiple holders
   - for Select

[Deadlock](https://en.wikipedia.org/wiki/Deadlock) - is a situation where two or more processes want to lock rows inside one table but need to wait for the other to complete, both would wait indefinitely

```sql
|------------------------------------------------ |------------------------------------------------------------|
|begin; /** transaction 1 **/                     | begin; /** transaction 2 **/                               |
|------------------------------------------------ |------------------------------------------------------------|
|update table1 where key=1;                       | update table1 where key=2;                                 |
|                                                 |                                                            |
|update table1 where key=2;                       |                                                            |
|                                                 |                                                            |
|...waits for Session2 to commit the data...      |                                                            |
|                                                 |                                                            |
|...waits for Session2 to commit the data...      | update table1 where key=1;                                 |
|                                                 |                                                            |
|...waits for Session2 to commit the data...      | ...waits for Session1 to commit the data which will never happen as Session1 is waiting on me...
|                                                 |                                                            |
|...waits for Session2 to commit the data...      | ...DEADLOCK error raised                                   |
|                                                 |                                                            |
|...waits for Session2 to commit the data...      | rollback;                                                  |
|                                                 |                                                            |
|commit;                                          |                                                            |
|------------------------------------------------ |------------------------------------------------------------|
```

```sql
Transaction #1
BEGIN;
SELECT * FROM `testlock` WHERE id=1 LOCK IN SHARE MODE; /* GET S LOCK */
SELECT SLEEP(5);
SELECT * FROM `testlock` WHERE id=1 FOR UPDATE; /* TRY TO GET X LOCK */
COMMIT;

Transaction #2
BEGIN;
SELECT * FROM `testlock` WHERE id=1 FOR UPDATE; /* TRY TO GET X LOCK - DEADLOCK AND ROLLBACK HERE */
COMMIT;
```


---
[MVCC](https://en.wikipedia.org/wiki/Multiversion_concurrency_control) (multiversion concurrency control) - is a concurrency control method commonly used by RDBMS to provide concurrent access to the database.

Features:
 - guarantees in the concurrent accesses to data
 - each connection uses a snapshot of the database at a particular instant in time
 - any changes made by a writer will not be seen by other users of the database until the changes have been completed
   - all readers don't block other readers
   - all writers don't block readers
   - all readers don't block writers

`MySQL`, `Oracle` and `MS SQL` uses `Undo Table Space`:
 - is a separate table to store commands with a delta of previous data variants
 - helps to retrieve/restore an old data block images
 - main data block contains only actual data in the rows at the moment
 - record history of executed statements

`PostgreSQL` uses `MVCC`:
 - values don't update and don't delete (immutable)
 - each tuple has fields: 
     - xmin (first transaction ID, added row to the table);
     - xmax (last transaction ID, deleted row in the table);
     - cmin (command number that added row); 
     - cmax (command number that deleted row);
 - uses sequential transaction numbers (INT type = 32 bit) that keep by each tuple
 - uses `VACUUM` is a tool to garbage-collect old tuples and optionally analyze a database
 - uses global transaction registry to define which transactions are running now and already rolled back


---
`MySQL` starts one process and many worker threads

`Oracle`, `PostgreSQL` start many worker processes
 - `postmaster` --(fork)--> `startup` defines data structures (transactional `xlog` buffer, commit `clog` buffer, buffer cache, `$PGDATA` file system structure) 
 - `postmaster` --(fork)--> `WAL writer` (write-ahead log)
 - `postmaster` --(fork)--> `writer` (write files data)
 - `postmaster` --(fork)--> `checkpointer` (merge buffer cache, `xlog` and `clog`)
 - `postmaster` --(fork)--> `autovacuum` launcher 
 - client connect to `postmaster` --(fork)--> create `server process`

 - client sent a statement `update table...` --(authentification)--> `server process`
   - `server process` --> `parse` client statement
   - `server process` --> `rewrite` client statement by statement optimizer 
   - `server process` --> build `query plan` of client statement
   - `server process` --> execute client statement (get data from disk)
   - `server process` --> write to `WAL`
   - `server process` --> update values in db (MVCC)
   - `server process` --> send response to the user
   - `server process` --> store WAL data to `pg_xlog/` buffer

 - client sent a statement `Commit;` --> `server process`
   - `server process` --> write buffer `xlog` and `clog` -->  fsync()
   - `server process` --> store data to `file system` logs
   - `postmaster` --(fork)--> `autovacuum` worker
   - `postmaster` --(fork)--> `autovacuum` worker


---
[TOAST](https://postgrespro.com/docs/postgresql/11/storage-toast) (The Oversized-Attribute Storage Technique)

 - `PostgreSQL` uses a fixed page size (commonly 8 Kb), and does not allow tuples to span multiple pages and it is not possible to store very large field values directly
 - `TOAST` is a technique when large field values are compressed and/or broken up into multiple physical rows
 - `TOAST` supports only data types with a variable-length (varlena) representation
 - values are divided (after compression if used) into chunks of at most `TOAST_MAX_CHUNK_SIZE` bytes
 - On-disk TOASTed values are kept in the `pg_toast` table
 - In-memory TOASTed pointers can point to data that is in the memory of the current server process


### Links
https://postgrespro.com/docs/postgresql/11/transaction-iso

https://postgrespro.com/docs/postgresql/11/storage-toast

https://postgrespro.com/docs/postgresql/11/sql-vacuum

https://postgrespro.com/docs/postgresql/11/explicit-locking
