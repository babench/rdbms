Data types
=======

### Run

 - Download the jar file of SchemaSpy from the [releases page](https://github.com/schemaspy/schemaspy/releases) (I use v6.0.0)
 - Download the jar file of [PostgreSQL JDBC driver](https://jdbc.postgresql.org/download.html) (version JDBC4.2)
 - Run the PostgreSQL instance by [Docker Compose](https://docs.docker.com/compose/) with
  ```
$ docker-compose -f ./02-data-types/docker-compose.yml up
  ```
 - Run SchemaSpy tool and generate HTML entity-relationship diagram (use defaults from `schemaspy.properties`)
```
/02-data-types$ java -jar ./schemaspy-6.0.0.jar
```
 - Open document `./diagram/index.html`

### Stop

 * The app is terminated by the response to a user interrupt such as typing `^C` (Ctrl + C) or a system-wide event of a shutdown
```bash
...
^CGracefully stopping... (press Ctrl+C again to force)
Killing otus-database  ... done
```

 * Remove containers and networks
```bash
$ docker-compose -f ./02-data-types/docker-compose.yml down
Removing otus-database ... done
Removing network 02-data-types_default
```

## Documentation

SQL-86 - 1st standard adopted ANSI in 1986 and approved ISO in 1987 (ISO/IEC 9075:1986)

SQL-89 - revised standard SQL-86 (ISO/IEC 9075:1989)

SQL-92 - 2nd standard, the most advertised version of SQL (ISO/IEC 9075:1992 and get FIPS 127-2)

SQL:1999 - 3rd standard: regexp, recursive selects, triggers, procedures, non-scalar and objects data types (ISO/IEC 9075:1999)

SQL:2003 - 4th revision of the SQL and clarifications for SQL-1999: window functions, sequence generators, support XML (ISO/IEC 9075:2003)

SQL:2006 - 5th revision of the SQL (ISO/IEC 9075:2006)

SQL:2008 - 6th revision of the SQL (ISO/IEC 9075:2008)

SQL:2011 - 7th revision of the SQL (ISO/IEC 9075:2011)

SQL:2016 - 8th revision of the SQL (ISO/IEC 9075:2016)

---


ANSI/ISO SQL doesn't have an Enum data type
 - MySQL and PostgreSQL have own implementations of Enum data type
 - other vendors offer other workarounds without native implementations

NULL is a special marker used to indicate that a data value doesn't exist
 - Edgar F. Codd introduced that NULL is a requirement for all true RDBMS
 - NULL is a reserved word used to identify this marker
 - NULL has been the focus of controversy because it is not a value like True or False it is a third logical result (unknown)
 - later, Edgar F. Codd had proposals to replaced NULL by two separate Null-type markers to indicate the reason why data is missing: 'A-Values' = 'Missing But Applicable' and  'I-Values' = 'Missing But Inapplicable', respectively


---


SQL defines standards of:
 - string types (SQL 89  and 92)
     - `char` (type with fixed size, unused values are space-padded)
     - `varchar` (type with variable-length)
     - `text` or `tinytext` or `mediumtext` and `longtext` (variable unlimited length, nonbinary strings, stored in a separate location)
     - `nchar` / `nvarchar` (national character type using Unicode characters)

 - large objects (SQL 99)
     - `clob` (a collection of character data usually stored in a separate location that is referenced in the table itself)
     - `blob` or `tinyblob` or `mediumblob` and `longblob` (binary strings data, stored in a separate location)
     - `nclob` (national character type using Unicode characters)
     - cannot be used in `group by` or `order by` clauses, in PK, FK or UNIQUE

 - numeric types (SQL 89 and 92)
     - `int` or `tinyint` or `smallint` or `bigint` (integer values)
     - `float` or `real` or `double` (approximate numerical value, mantissa precision p)
     - `decimal` or `numeric` (exact numerical; numeric(precision, scale) = precision p, scale s)

 - date and time types (SQL 89 and 92)
     - `date` (date of year: yyyy-mm-dd)
     - `time` [with time zone] (time of day types: hh:mm:ss)
     - `timestamp` [with time zone] (combination of date and time values separated by a space with time zone: yyyy-mm-dd hh:mm:ss)
     - `interval` (used to represent a measure of time between two values: days, hours, minutes, seconds and possibly fractions of a second)

 - `boolean` type (SQL 2003)
     - (true | false) values
     - supports in PostgreSQL and has a type alias in MySQL to `tinyint`

 - composite types (SQL 99)
     - `array` (collections of values in single column)
     - `row` (structured values in single column)

 - `xml` type (SQL 2003 and 2006)
     - native support without first converting it to XML from one of the other SQL data types
     - type guarantees that data values should be a validated XML
     - XQuery for XML extraction and updating document

 - `json` type (SQL 2016)
     - the standard uses strings to store JSON data, not define a native type but does not prevent vendors from providing a self JSON type
     - defines functions that interpret strings as JSON data (json_object, json_array and others)
     - database vendors could support different JSON formats but RFC 7159 is the mandatory default
     - specifies a SQL/JSON path language for JSON, it adopts many features from ECMAScript ($.name, $.events[last] and others)


---


 - Surrogate key (system-generated key) - a unique identifier for the entity object in the database that has no relationship to the real-world meaning of the data held in a row
 - Natural key (business key) - is a type of unique key that is formed of attributes have a logical relationship to the attributes within that row

