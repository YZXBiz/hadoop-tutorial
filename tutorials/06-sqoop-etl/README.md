# Tutorial 06: Sqoop ETL

Learn data transfer between databases and Hadoop using Apache Sqoop.

## Learning Objectives

- Understand Sqoop architecture
- Import data from MySQL/RDBMS to HDFS
- Export data from HDFS to databases
- Handle incremental imports
- Transform data during transfer

## Prerequisites

- HDFS running
- MySQL/MariaDB accessible (included in setup)
- Sqoop installed (included in images)

## Sqoop Architecture

### Components
- **Sqoop Client**: Command-line interface
- **Connectors**: Database-specific modules (MySQL, PostgreSQL, Oracle, etc.)
- **Drivers**: JDBC drivers for databases

### Data Flow
```
RDBMS Database ←→ Sqoop ←→ HDFS (or local file system)
```

## Basic Sqoop Commands

### Import Operations

#### Import Single Table

```bash
docker-compose exec namenode bash

# Basic import
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees

# Import with column selection
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --columns "name,salary,department" \
  --target-dir /user/sqoop/employees_salary
```

#### Import with WHERE Clause

```bash
# Import only high salary employees
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --where "salary > 80000" \
  --target-dir /user/sqoop/high_earners
```

#### Incremental Import

```bash
# First full import
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_incr \
  --incremental append \
  --check-column employee_id \
  --last-value 0

# Subsequent incremental imports
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_incr \
  --incremental append \
  --check-column employee_id \
  --last-value 1015
```

### Export Operations

#### Export to MySQL

```bash
# Create table in MySQL first
# Then export from HDFS

sqoop export \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees_backup \
  --export-dir /user/sqoop/employees \
  --input-fields-terminated-by ','
```

### List Available Tables

```bash
sqoop list-tables \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root
```

### Check Table Structure

```bash
sqoop eval \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --query "SELECT * FROM employees LIMIT 5"
```

## Advanced Features

### Parallel Processing

```bash
# Import with 4 parallel mappers
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees \
  --num-mappers 4 \
  --split-by employee_id
```

### Output Formats

#### Text Format (Default)
```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --as-textfile
```

#### Parquet Format (Columnar)
```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --as-parquetfile
```

#### SequenceFile Format
```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --as-sequencefile
```

### Data Compression

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees \
  --compress \
  --compression-codec org.apache.hadoop.io.compress.GzipCodec
```

### Field and Record Delimiters

```bash
# Custom delimiters
sqoop import \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees \
  --fields-terminated-by '|' \
  --lines-terminated-by '\n'
```

## Create Test Data in MySQL

```bash
# Connect to MySQL
docker-compose exec mariadb mysql -u root -proot

# In MySQL:
CREATE DATABASE IF NOT EXISTS test;
USE test;

CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name VARCHAR(100),
  department VARCHAR(50),
  salary DECIMAL(10, 2),
  age INT,
  hire_date DATE
);

INSERT INTO employees VALUES
  (1, 'Alice', 'Engineering', 95000, 32, '2018-03-15'),
  (2, 'Bob', 'Sales', 65000, 28, '2019-06-20'),
  (3, 'Carol', 'Engineering', 92000, 35, '2017-01-10'),
  (4, 'David', 'Marketing', 72000, 31, '2019-04-12'),
  (5, 'Emma', 'Finance', 88000, 42, '2016-09-08');

-- Create backup table for export test
CREATE TABLE employees_backup LIKE employees;

-- Verify
SELECT * FROM employees;
EXIT;
```

## Complete ETL Pipeline

```bash
#!/bin/bash
# sqoop_etl.sh

MYSQL_HOST="mariadb"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_DB="test"
HDFS_USER="hadoop"

echo "Starting Sqoop ETL Pipeline..."

# Step 1: Import employees from MySQL
echo "Importing employees..."
sqoop import \
  --connect jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$MYSQL_DB \
  --username $MYSQL_USER \
  --password $MYSQL_PASS \
  --table employees \
  --target-dir /user/sqoop/employees \
  --delete-target-dir \
  --num-mappers 1

# Step 2: Verify import
echo "Verifying import..."
hadoop fs -ls /user/sqoop/employees/
hadoop fs -cat /user/sqoop/employees/part-m-00000 | head -5

# Step 3: Process data with Hive
echo "Processing with Hive..."
# (Create Hive table over the data)

# Step 4: Export processed data back
echo "Exporting results..."
sqoop export \
  --connect jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/$MYSQL_DB \
  --username $MYSQL_USER \
  --password $MYSQL_PASS \
  --table employees_backup \
  --export-dir /user/sqoop/employees \
  --input-fields-terminated-by ','

echo "ETL Pipeline complete!"
```

## Troubleshooting

### Connection Issues
```bash
# Test database connectivity
sqoop eval \
  --connect jdbc:mysql://mariadb:3306/test \
  --username root \
  --password root \
  --query "SELECT 1"
```

### JDBC Driver Issues
```bash
# Check JDBC driver location
find /opt -name "mysql*.jar"

# Set classpath if needed
export SQOOP_CLASSPATH="/path/to/driver.jar"
```

### Permission Issues
```bash
# Check Hadoop permissions
hadoop fs -ls -R /user/sqoop/

# Change permissions if needed
hadoop fs -chmod -R 777 /user/sqoop/
```

## Best Practices

1. **Use --num-mappers**: Parallelize imports for large tables
2. **Set --split-by**: Use a good split column for even distribution
3. **Compress data**: Save storage with --compress flag
4. **Validate imports**: Always verify imported data
5. **Incremental updates**: Use --incremental for frequent syncs
6. **Error handling**: Log failures and setup retry mechanism

## Exercises

1. Set up test database with sample data
2. Import employees table to HDFS
3. Process the data with Hive (filter, aggregate)
4. Export results back to a new MySQL table
5. Set up an incremental import script

## Performance Tuning

```bash
# Use faster format
sqoop import ... --as-parquetfile

# Parallel with multiple mappers
sqoop import ... --num-mappers 8 --split-by id

# Compression
sqoop import ... --compress --compression-codec gzip

# Batch import
sqoop import ... --fetch-size 10000
```

## Sqoop Command Syntax Reference

```
sqoop import [GENERIC_OPTIONS] [IMPORT_OPTIONS]
sqoop export [GENERIC_OPTIONS] [EXPORT_OPTIONS]
sqoop list-tables [GENERIC_OPTIONS]
sqoop list-databases [GENERIC_OPTIONS]
sqoop eval [GENERIC_OPTIONS] [EVAL_OPTIONS]
sqoop codegen [GENERIC_OPTIONS] [CODEGEN_OPTIONS]
sqoop create-hive-table [GENERIC_OPTIONS] [CREATE_OPTIONS]
sqoop merge [GENERIC_OPTIONS] [MERGE_OPTIONS]
```
