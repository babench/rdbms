Design the database
=======

### Goal

 - Business tasks:
   - make an order to buy a product in an e-commerce store `call next_store_order('product 1', 22, 'dmitriy@invalid.test');`
   - be able to cancel a not delivered product yet from an e-commerce store `call cancel_store_order(1, 1);`
   - be able to change the count of products in an not paid order `call change_order_count(1, 1, 48);`
   - change order status step by step `call change_store_order_status(2, 1, 'paid');`
     - statuses (`not_paid`, `paid`, `canceled`, `packed`, `shipped`, `delivered`, `lost`, `returned`)
   - change product price `call change_product_price('product 2', 'ingvar@invalid.test', 53.0);`

  - Open the documentation `./diagram/index.html`
  - Open the ER diagram `./e-commerce_store.pdf`
  - Replication could be done with:
    - 1 master server
    - 1 hot slave server in a standby mode
    - 1 slow slave server in a master/slave mode (for reports and analytics)
 - Sharding ...


## Run

 - Run the PostgreSQL instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./05-design-database/docker-compose.yml up
$ docker exec -ti otus-database bash
bash-4.4# psql -U store_user -d store
psql (11.4)
Type "help" for help.
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
$ docker-compose -f ./05-design-database/docker-compose.yml down
Removing otus-database ... done
Removing network 05-design-database_default
```


## Documentation

`Conceptual model` - is a representation of a system, made of the composition of concepts which are used to help people know, understand, or simulate a subject the model represents
 - define entities with documentation
 - define relationships between entities
 - create ER diagram
 - define attributes
 - define keys for PK/FK/UNIQUE and indexes

`Logical schema` - is a database model expressed in terms of a data model and implementation technology
 - which database vendor do you use (PostgreSQL/Oracle, MongoDB/Cassandra/ClickHouse)
 - set of tables
 - data decomposition on a sequence of components
 - database normalization to reduce data redundancy
 - denormalization data to increase performance of data retrieval in a specific case
 - define a set of database transactions for business tasks
 - data integrity support (constraints, data types)
 - collaboration between developers and the customer about technical review and the final logical model

`Physical model` - is a model defines how the data is stored and how to access the data
 - designing tables for the chosen database
 - define business logic on a database layer or a software layer; OLTP or OLAP jobs
 - define a transactional model for isolation level in ACID
 - resource planning (RAM, CPU, storage and network)
 - data organization with vertical or horizontal scaling
 - security rules and protection of vulnerability
 - maintenance and monitoring of resources and workload
 - data storage structure on a single instance or a replica set and shards, or data cloud
 - define current workload, performance, and expected future growth
 - performance and high availability requirements
 - define rules for a backup
 - use CI/CD


---
`OLTP` (Online Transaction Processing) - organizing the real-time database work with a large flow of small-time transactions and responds immediately to user requests

features:
 - large flow of small-time transactions
 - large number concurrent connections
 - many users
 - good normalization for quickly insert/update

requirements:
 - short transaction times
 - concurrent workloads
 - minimal downtime
 - backup schedule
 - not big data store

disadvantages:
 - performance degradation with a lot of indexes
 - performance degradation with a big data store (for many previous years)


---
`DWH` (Data Warehouse) - storage stores current and historical data in one single place that are used for creating analytical reports and is considered a core component of business intelligence

features:
 - select data from different sources (ERP, CRM, HR, ECM) by ETL (Extract, Transform, Load)
 - long-running transactions
 - denormalized data
 - analytics and making decision system
 - need a lot of indexes

disadvantages:
 - accumulates deleted data during long-term operations
 - only to select data not to update


---
`OLAP` (Online Analytical Processing) - organizing the database characterized by long-time transactions and much more complex queries to huge amounts of data for the purpose of business intelligence or reporting

```
Database 1  -->
Database 2  -->  Data Warehouse  -->  OLAP cube  -->  reporting table
...
Database N  -->
```

`OLAP cube` - is a multi-dimensional array of data, hypercube if N > 3
example:  summarize financial data by `product`, by `time-period`, and by `city` to compare actual and budget expenses


---
`Replication` is the process of copying data from one source to another (or to many others) and Vice versa.
 - master/slave (all transactions income to a master server, master writes data to a slave server)
 - standby (streaming a log of updates to a backup process, which can then take over if the primary server fails)
 - master-master (each server stores own data and backup from others)

`Sharding` is a data tier architecture, where data is horizontally partitioned across independent databases by rule; each database is called a `shard`


---
`Backup` - copying data into an archive file that may be used to restore the original data if they are lost
 - full
   - backup method contains complete source data
   - each time per week or month, or quarter
 - differential
   - each time copies all files that changed since the last full backup
   - quicker than full backups
 - incremental
   - stores changed data only after the previous backup
   - shorter the time intervals between backups

`Cold backup` - is a database backup during which the database is offline and not accessible to update; ensures a consistent state
`Hot backup` - allows the end user to backup the database while it is running with concurrent user manipulations; inconsistent state

`T1` - data recovery time is more important than `T2` - backup time
