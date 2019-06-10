Relational algebra and model data
=======
Schema of prototype e-commerce store:
 - _manufacturer_ (manufacturers of items/goods)
 - _supplier_ (companies responsible for the logistics)
 - _account_ (e-commerce store accounts) 
 - _item_ (items/goods of the e-commerce store)
 - _item_property_ (properties for each item)
 - _item_price_ (item prices depend on manufacturers and suppliers)
 - _order_ (clients orders)
 - _order_details_ (detailed information by each order)
 - _order_log_ (orders changelog)


## Documentation
1970 - Edgar F. Codd suggest a relational model in a paper "A Relational Model of Data for Large Shared Data Banks"

1974 - IBM started a research subproject "System R" named later to IBM DB2

1979 - Relational Software, Inc released first commercial SQL RDBMS Oracle v2, later also known as Oracle Database 

Database Server consist of:
 - database
   - control files (meta data describes database files)
   - log files
   - user data (tables, columns, indexes, ...)
 - instance (set of maintenance processes and memory blocks in RAM)
   - data (files mapping from a disk, execute plans, parsing SQL expressions and optimizations)
   - processes (reader, writer, logging, checkpoint)

---

Relation - is a two-dimensional table structure definition (in mathematics) with the data appearing in that structure
Relational algebra based on:
 - set theory (set union, set difference, and Cartesian product) with additional constraints to these operators
 - a set of operators uses relations as arguments and returns relations as value
 - has closure on herself for example relational operators could use other relational operators with a compatible types

Definitions:
 - domain = table column
 - tuple = row column
 - attribute = column name 
 - relation = table
 - degree = number of columns
 - cardinality = number of rows

Relational operations:
 - A ∪ B (union)
 - A ∩ B (intersect)
 - A - B (difference)
 - A x B (cartesian product)
 - A[a, b] (project)
 - A (select)
 - A ⋈ B (join)
 - A ÷ B (division)

---

Codd's 12 rules to define what is required from a database management

 - Rule 0. For any system that is advertised as, or claimed to be, a relational database management system, that system must be able to manage databases entirely through its relational capabilities.

 -	Rule 1. All information in a relational database is represented explicitly at the logical level and in exactly one way – by values in tables.

 -	Rule 2. Each value in a relational database is guaranteed to be logically accessible by resorting to a combination of the table name, primary key value and column name.

 -	Rule 3. "Null" values are supported in fully relational database for representing missing or inapplicable information independent of a data type; distinct from the empty or blank character string, from zero or any other number.

 -	Rule 4. The database description (metadata) is represented at the logical level in system tables the same way as ordinary data.

 -	Rule 5. A relational system should have at least one language whose statements are expressible, per some well-defined syntax, for data definition, data manipulation, transactions, and data consistency.

 -	Rule 6. All databases should support a logical combination of data: virtual views

 -	Rule 7. All operations on data are operations on the set of data; record in a database is an element of a two-dimensional dataset with a relational algebra operation.

 -	Rule 8. Physical data representation is separated from applications works on a database. Applications don't know what data is and how it is stored.

 -	Rule 9. Applications are separated from logical data organization.

 -	Rule 10. Integrity constraints specific to a particular relational database aren't supported on the application level.

 -	Rule 11. The end-user shouldn't be able to see that the data is distributed by various locations in a network. Users should always get the impression that the data is located at one site only.

 -	Rule 12. A relational system should modify data structures only by high-level relational language.

---

Null:
 - doesn't have a data type
 - field with no value (not a default value)
 - could be applied to any data type field
 - each action with Null returns Null
 - each comparison with Null returns Unknown
 - there is a special function determines Null value (true|false)

---

Database Normalization - is a technique of organizing the data in the database. It encompasses a set of procedures designed to eliminate non-simple domains (non-atomic values) and the redundancy (duplication) of data.
 - 1NF: all attributes should be atomic (single value)
 - 2NF: 1NF + simple PK => (split the main table to several tables with PK and FK)
 - 3NF: 2NF + don't have attributes with transitive dependency
 - BCNF: 3NF + all attributes that aren't part of a PK depend on the PK, but not on part of it
