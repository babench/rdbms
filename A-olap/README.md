OLAP description
=======

1993 - E. Codd describe `OLAP` like a concept for a data analyst

`OLAP` is a category of software that allows users to analyze information from multiple database systems at the same time.
Analysts frequently need to group, aggregate and join data. These operations in relational databases (`OLTP`) are resource intensive. With `OLAP` data can be pre-calculated and pre-aggregated, making analysis faster.


---
Top `OLAP` Tools

1. [IBM Cognos](https://en.wikipedia.org/wiki/IBM_Cognos_Analytics)
2. [Micro Strategy](https://en.wikipedia.org/wiki/MicroStrategy)
3. [Jedox Palo BI Suite](https://en.wikipedia.org/wiki/Palo_(OLAP_database\))
4. [Apache Kylin](https://en.wikipedia.org/wiki/Apache_Kylin)
5. [IcCube](https://en.wikipedia.org/wiki/IcCube)
6. [Pentaho BI Suite](https://en.wikipedia.org/wiki/Pentaho)
7. [Oracle BI](https://en.wikipedia.org/wiki/Oracle_Business_Intelligence_Suite_Enterprise_Edition)
8. [Microsoft Analysis Services](https://en.wikipedia.org/wiki/Microsoft_Analysis_Services)


---
Codd's 12 rules to a formalized redefinition of the requirements for `OLAP` Tools:

 - Rule 1. Multi-dimensional conceptual view: `OLAP` tools should allow users with a multi-dimensional model that keep up a correspondence to users' views of the enterprise and is intuitively analytical and simple to use.

 - Rule 2. Transparency: The user is able to get all the necessary data from the `OLAP-cube`, not really to know where are they come from.

 - Rule 3. Accessibility: The `OLAP` tool also let to access data needed for the analysis from all heterogeneous enterprise data sources such as relational, non-relational, and legacy methods.

 - Rule 4. Consistent reporting performance: With the number of dimensions, levels of aggregations, and the size of the database raises, users ought to not perceive any significant fall in performance.

 - Rule 5. Client-server architecture: The `OLAP` system should be proficient enough to operate efficiently in a client-server environment. Different clients are able to connect to the server part with minimum effort.

 - Rule 6. Generic dimensionality: Every data dimension must be the same in both structure and operational capabilities, i.e., the basic structure, formulae, and reporting should not be biased towards any dimension.

 - Rule 7. Dynamic sparse matrix handling: The `OLAP` system should be able to cope up with the physical schema to the specific analytical model that optimizes sparse matrix handling to achieve and maintain the required level of performance.

 - Rule 8. Multi-user support: The `OLAP` system should be able to hold up a group of users working at the same time on the same or different models of the enterprise's data.

 - Rule 9. Unrestricted cross-dimensional operations: The `OLAP` system must be able to identify the dimensional hierarchies and automatically perform associated roll-up calculations across dimensions.

 - Rule 10. Intuitive data manipulation: Slicing and cubing, consolidation (roll-up), and other manipulations can be accomplished via direct 'point-and-click' or 'drag-and-drop' actions on the cells of the cube without to use menus or multiple operations.

 - Rule 11. Flexible reporting: The capability of arranging rows, columns, and cells in a way that facilitates analysis by an intuitive visual presentation of analytical reports must exist.

 - Rule 12. Unlimited dimensions and aggregation levels: Depending on business needs, an analytical model may have some dimensions each having multiple hierarchies.


---
Basic analytical operations of OLAP

 - `roll up`
   - is also known as "consolidation" or "aggregation" operations:
     - reducing source dimensions = cities "New Jersey" and "Lost Angles" -> country USA)
     - climbing up concept hierarchy = quater dimension is removed

 - `drill down`
   - data is fragmented into smaller parts (opposite of the `roll up` process):
     - moving down the concept hierarchy = quater is drilled down to months January, February, and March
     - increasing a dimension = add months dimensions

 - `slice` and `dice`:
   - 1 dimension is selected, and a new sub-cube is created = slice for 1st (quater x cities) and items -> matrix
   - multiple dimensions are selected and a new sub-cube is created = location is ("Perth" or "Sydney") and time is (Q1 or Q2) and item is (books or clothes)

 - `pivot`/`rotate`
   - rotate the data axes to provide a substitute presentation of data = (cities x items) -> (items x cities)

 - `drill across`
   - reconciles cells from several data cubes which share the same scheme

 - `drill through`
   - enables to navigate from data at the lower level in a cube to dimensions from a selected cell


---

```
                (Y) month:
                Sept | Oct | ...
                  /   /
               +------+         
              /      /|         
(X) cities:  +------+ |
 Moscow -    | ∆    | +  (Z) products:
 Tver -      |      |/   - apple
 ... -       +------+    - pear
                         - ...

dimension's measure:
city: Moscow
month: September
product: apple
profit: 63 000 RUB
```

 - `OLAP` cube (hypercube) in a relational model like
   - measures table (each row is a cube column)
   - dimension table (each row is a coordinate in dimension)

 - array indexes are dimensions or `cube axis`
 - array elements values is `cube measures`


`ROLAP` - is a relational `OLAP`
  - based on RDBMS with
  - SQL reporting tool
  - scalable in handling large data volumes
  - ability to fine-tune the extract, transform, load (ETL) code 
  - load times are generally much shorter than with the automated `MOLAP` loads
  - schema "star": center - measures table, rays - dimension tables
  - schema "snowflake": center - measures table, rays - dimension tables + additional relations

`MOLAP` - is a multidimensional `OLAP`
  - classical `OLAP` system
  - stores data in an optimized multi-dimensional array storage
  - fast query performance due to optimized storage, multidimensional indexing and caching

`HOLAP` - is a hybrid `OLAP`
  - uses RDBMS to store data and multidimensional tables for aggregations

[Multidimensional Expressions (MDX)](https://en.wikipedia.org/wiki/MultiDimensional_eXpressions) - is a query language for `OLAP` using a database management system
```sql
select 
  {
    [Territory].[Cities by Countries].[All].[Russia],
    [Territory].[Cities by Countries].[All].[Ukrain]
  } on rows
from [invoices1]
```

---
Links: 
https://habr.com/ru/post/126810
https://sqljunkieshare.com/2013/04/25/creating-querying-tuning-hierarchical-rolap-cubes-in-oracle/
