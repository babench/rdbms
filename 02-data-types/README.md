Data types
=======

## Documentation

SQL-86: 1st standard adopted ANSI и approved ISO in 1987

SQL-89: revised standard SQL-86

SQL-92: 2nd standard, the most advertised version of SQL (ISO 9075 and get FIPS 127-2)

SQL-1999: 3rd standard (regexp, recursive selects, triggers, procedures, non-scalar and objects data types)

SQL-2003: (window functions, sequence generators, support XML)


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
     - char (type with fixed size, unused values are space-padded)
     - varchar (type with variable-length)
     - text or TINYTEXT or MEDIUMTEXT and LONGTEXT (variable unlimited length, nonbinary strings, stored in a separate location)
     - nchar / nvarchar / nclob (NATIONAL CHARACTER type using Unicode characters)

 - large objects (SQL 99)
     - clob (a collection of character data usually stored in a separate location that is referenced in the table itself)
     - blob or TINYBLOB or BLOB or MEDIUMBLOB and LONGBLOB (binary strings data, stored in a separate location)
     - nclob (NATIONAL CHARACTER type using Unicode characters)
     - cannot be used in GROUP BY or ORDER BY clauses, in PK, FK or UNIQUE

 - numeric types (SQL 89 and 92)
     - int or TINYINT or SMALLINT or BIGINT (integer values)
     - FLOAT or REAL or DOUBLE (approximate numerical value, mantissa precision p)
     - decimal or numeric (exact numerical; numeric(precision, scale) = precision p, scale s)

 - date and time types (SQL 89 and 92)
     - date (date of year: yyyy-mm-dd)
     - time [with time zone] (time of day types: hh:mm:ss)
     - TIMESTAMP [WITH TIME ZONE] (combination of DATE and TIME values separated by a space with time zone: yyyy-mm-dd hh:mm:ss)
     - INTERVAL (used to represent a measure of time between two values: days, hours, minutes, seconds and possibly fractions of a second)

 - boolean type (SQL 2003)
     - (true | false) values
     - supports in PostgreSQL and has a type alias in MySQL to TINYINT

 - composite types (SQL 2003)
     - ARRAY (collections of values in single column)
     - ROW (structured values in single column)

 - xml type (SQL 2003 and 2006)
     - native support without first converting it to XML from one of the other SQL data types
     - type guarantees that data values should be a validated XML
     - XQuery for XML extraction and updating document

 - json type (SQL 2016)
     - the standard uses strings to store JSON data, not define a native type but does not prevent vendors from providing a self JSON type
     - defines functions that interpret strings as JSON data (json_object, json_array and others)
     - database vendors could support different JSON formats but RFC 7159 is the mandatory default
     - specifies a SQL/JSON path language for JSON, it adopts many features from ECMAScript ($.name, $.events[last] and others)


---


 - Surrogate key (system-generated key) - a unique identifier for the entity object in the database that has no relationship to the real-world meaning of the data held in a row
 - Natural key (business key) - is a type of unique key that is formed of attributes have a logical relationship to the attributes within that row

