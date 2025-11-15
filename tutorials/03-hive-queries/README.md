# Tutorial 03: Hive SQL Queries

**Duration:** 45-60 minutes
**Difficulty:** Beginner
**Prerequisites:** Complete Tutorials 01-02 (HDFS & MapReduce)

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What Hive is** and why SQL on Hadoop is revolutionary
- **How Hive converts SQL** to MapReduce jobs automatically
- **When to use Hive** vs writing MapReduce code
- **How to create tables** and query big data with familiar SQL
- **Performance optimization** for Hive queries

**Real-world relevance:** Facebook created Hive to let analysts query petabytes of data using SQL instead of writing Java MapReduce. Companies like Netflix, Uber, and Airbnb use Hive for data warehousing and analytics.

---

## Conceptual Overview: What is Hive?

### The Problem Hive Solves

**Scenario:** You need to analyze user clickstream data to find popular products.

**Option 1: Write MapReduce (Tutorial 02 style)**
```java
// 200+ lines of Java code
public class ClickAnalyzer {
  public static class ClickMapper extends Mapper<...> {
    // Mapper logic: parse logs, extract product_id
  }
  public static class ClickReducer extends Reducer<...> {
    // Reducer logic: count clicks per product
  }
  // Job configuration, compilation, JAR packaging...
}
```
**Problem:** Takes hours/days, requires Java skills, error-prone

**Option 2: Use Hive SQL**
```sql
SELECT product_id, COUNT(*) as clicks
FROM clickstream
GROUP BY product_id
ORDER BY clicks DESC
LIMIT 10;
```
**Benefit:** 4 lines, runs in minutes, anyone who knows SQL can do it!

---

### What is Hive?

```
Hive = SQL Interface + Schema + MapReduce Compiler

┌────────────────────────────────────────────┐
│         You write SQL queries              │
│   SELECT * FROM users WHERE age > 30       │
└──────────────────┬─────────────────────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │   Hive Compiler     │
         │ Converts SQL → MR   │
         └────────┬────────────┘
                  │
                  ▼
      ┌───────────────────────┐
      │  MapReduce Job Runs   │
      │  (Just like Tutorial  │
      │      02, but auto!)   │
      └───────────────────────┘
                  │
                  ▼
            ┌─────────────┐
            │   Results   │
            │  in HDFS    │
            └─────────────┘
```

**Key insight:** You write SQL, Hive generates MapReduce jobs for you!

---

### Hive Components

```
┌──────────────────────────────────────────────────┐
│         HiveServer2 (Port 10000)                 │
│    SQL parser, compiler, query optimizer         │
└─────────────────┬────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
┌────────┐  ┌──────────┐  ┌─────────┐
│ Client │  │ Metastore│  │  YARN   │
│ (You)  │  │(MariaDB) │  │(Runs MR)│
└────────┘  └──────────┘  └─────────┘
                  │
                  ▼
         Table Metadata:
         - Table names
         - Column types
         - File locations
         - Partitions
```

| Component | What It Does | Where It Lives |
|-----------|--------------|----------------|
| **HiveServer2** | Accepts SQL queries, compiles to MapReduce | Port 10000 (Thrift), 10002 (Web UI) |
| **Metastore** | Stores table schemas & metadata | MariaDB database |
| **HDFS** | Stores actual data files | DataNodes |
| **YARN** | Executes the MapReduce jobs | ResourceManager/NodeManager |

---

### Hive vs Traditional Database

| Feature | Traditional DB (MySQL) | Hive |
|---------|------------------------|------|
| **Data size** | GB - TB | TB - PB |
| **Query speed** | Milliseconds | Seconds - Minutes |
| **Updates** | Row-level INSERT/UPDATE/DELETE | Append-only (mostly) |
| **Best for** | Transactional, OLTP | Analytics, OLAP |
| **Schema** | Schema-on-write (strict) | Schema-on-read (flexible) |
| **Storage** | Local disk/SAN | Distributed (HDFS) |

**When to use Hive:**
- ✅ Analyzing large datasets (> 100GB)
- ✅ Batch analytics (daily/hourly reports)
- ✅ Data warehousing
- ✅ ETL transformations
- ✅ SQL-familiar team

**When NOT to use Hive:**
- ❌ Real-time queries (< 1 second latency)
- ❌ Frequent updates/deletes
- ❌ Small datasets (< 10GB) - overhead not worth it
- ❌ OLTP workloads

---

## Hands-On: Working with Hive

### Exercise 1: Connect to Hive

**Method 1: Hive CLI (Simple)**
```bash
docker-compose exec hive-server hive
```

**Expected output:**
```
Hive Session ID = a1b2c3d4-e5f6-7890-abcd-ef1234567890

Logging initialized using configuration in jar:file:/opt/hive/lib/hive-common-3.1.3.jar!/hive-log4j2.properties

hive>
```

**What just happened:**
- Connected to HiveServer2 inside the container
- Hive CLI is ready for SQL commands
- You're now at the `hive>` prompt

**Method 2: Beeline (JDBC, Production-style)**
```bash
# From inside hive-server container
beeline -u "jdbc:hive2://localhost:10000" -n hadoop
```

**For this tutorial:** We'll use the simpler Hive CLI

---

### Exercise 2: Explore the Metastore

**Check existing databases:**
```sql
SHOW DATABASES;
```

**Expected output:**
```
OK
default
Time taken: 0.123 seconds, Fetched: 1 row(s)
```

**What this shows:**
- `default` = Built-in database (like public schema in PostgreSQL)
- Time taken = How long the command took
- This is just metadata - querying MariaDB, not running MapReduce

**Create your own database:**
```sql
CREATE DATABASE learning;
USE learning;
```

**Expected output:**
```
OK
Time taken: 0.091 seconds
OK
Time taken: 0.034 seconds
```

**Verify:**
```sql
SELECT current_database();
```

**Output:**
```
OK
learning
Time taken: 0.056 seconds, Fetched: 1 row(s)
```

---

### Exercise 3: Upload Sample Data to HDFS

**Exit Hive temporarily:**
```sql
EXIT;
```

**Connect to NameNode:**
```bash
docker-compose exec namenode bash
```

**Create directories and upload CSV files:**
```bash
# Create Hive warehouse directory
hadoop fs -mkdir -p /user/hive/warehouse/learning.db/

# Upload sample data
hadoop fs -put /datasets/structured/employees.csv /tmp/employees.csv
hadoop fs -put /datasets/structured/customers.csv /tmp/customers.csv
hadoop fs -put /datasets/structured/products.csv /tmp/products.csv

# Verify upload
hadoop fs -ls /tmp/*.csv
```

**Expected output:**
```
-rw-r--r--   2 hadoop supergroup    15234 2025-11-15 12:00 /tmp/employees.csv
-rw-r--r--   2 hadoop supergroup    23456 2025-11-15 12:00 /tmp/customers.csv
-rw-r--r--   2 hadoop supergroup    12345 2025-11-15 12:00 /tmp/products.csv
```

**Preview the data:**
```bash
hadoop fs -cat /tmp/employees.csv | head -5
```

**Expected output (CSV format):**
```
employee_id,name,department,salary,age,hire_date
1,John Smith,Engineering,95000,28,2020-03-15
2,Jane Doe,Sales,78000,32,2019-07-22
3,Mike Johnson,Engineering,102000,35,2018-01-10
4,Sarah Williams,Marketing,85000,29,2021-06-01
```

**Return to Hive:**
```bash
docker-compose exec hive-server hive
USE learning;
```

---

### Exercise 4: Create Your First Table

**Create employees table:**
```sql
CREATE TABLE employees (
  employee_id INT,
  name STRING,
  department STRING,
  salary DOUBLE,
  age INT,
  hire_date STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");
```

**Expected output:**
```
OK
Time taken: 0.234 seconds
```

**What each line means:**

```sql
CREATE TABLE employees (         -- Table name
  employee_id INT,               -- Column name and type
  ...
)
ROW FORMAT DELIMITED            -- How to parse rows
FIELDS TERMINATED BY ','        -- CSV delimiter
STORED AS TEXTFILE              -- File format (plain text)
TBLPROPERTIES (
  "skip.header.line.count"="1"  -- Skip CSV header row
);
```

**Check table structure:**
```sql
DESCRIBE employees;
```

**Expected output:**
```
OK
employee_id             int
name                    string
department              string
salary                  double
age                     int
hire_date               string
Time taken: 0.045 seconds, Fetched: 6 row(s)
```

---

### Exercise 5: Load Data into Table

**Load the CSV file:**
```sql
LOAD DATA INPATH '/tmp/employees.csv'
INTO TABLE employees;
```

**Expected output:**
```
Loading data to table learning.employees
OK
Time taken: 0.512 seconds
```

**What just happened:**

```
Before:
  /tmp/employees.csv  ← Data file in HDFS

After:
  /user/hive/warehouse/learning.db/employees/employees.csv
                                              ↑
                              Hive MOVED the file here!

Important: LOAD DATA INPATH moves files (doesn't copy)!
```

**Verify the table has data:**
```sql
SELECT * FROM employees LIMIT 5;
```

**Expected output:**
```
OK
1       John Smith      Engineering     95000.0     28      2020-03-15
2       Jane Doe        Sales           78000.0     32      2019-07-22
3       Mike Johnson    Engineering     102000.0    35      2018-01-10
4       Sarah Williams  Marketing       85000.0     29      2021-06-01
5       Tom Brown       Sales           72000.0     26      2022-02-14
Time taken: 1.234 seconds, Fetched: 5 row(s)
```

**Why did this query take 1+ seconds?**
- Hive launched a MapReduce job!
- Even simple SELECT runs distributed processing
- Check ResourceManager UI: http://localhost:8088

---

### Exercise 6: Create Remaining Tables

**Create customers table:**
```sql
CREATE TABLE customers (
  customer_id INT,
  name STRING,
  email STRING,
  region STRING,
  join_date STRING,
  total_spend DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

LOAD DATA INPATH '/tmp/customers.csv'
INTO TABLE customers;
```

**Create products table:**
```sql
CREATE TABLE products (
  product_id INT,
  product_name STRING,
  category STRING,
  price DOUBLE,
  stock_quantity INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

LOAD DATA INPATH '/tmp/products.csv'
INTO TABLE products;
```

**Verify all tables:**
```sql
SHOW TABLES;
```

**Expected output:**
```
OK
customers
employees
products
Time taken: 0.034 seconds, Fetched: 3 row(s)
```

---

## Basic SQL Queries

### Query 1: Simple SELECT

```sql
SELECT name, department, salary
FROM employees
LIMIT 10;
```

**What happens under the hood:**
1. Hive creates MapReduce job
2. Mappers read files from HDFS
3. Select only needed columns (projection)
4. Return first 10 rows

**Expected output:**
```
OK
John Smith      Engineering     95000.0
Jane Doe        Sales           78000.0
Mike Johnson    Engineering     102000.0
...
Time taken: 2.145 seconds, Fetched: 10 row(s)
```

---

### Query 2: WHERE Filtering

```sql
SELECT name, salary
FROM employees
WHERE salary > 90000;
```

**What happens:**
- Mappers filter rows where salary > 90000
- Only matching rows returned
- This is a **map-only job** (no reduce needed)

**Expected output:**
```
OK
John Smith      95000.0
Mike Johnson    102000.0
Alice Cooper    98000.0
Time taken: 1.987 seconds, Fetched: 3 row(s)
```

**Try complex conditions:**
```sql
SELECT name, department, salary, age
FROM employees
WHERE department = 'Engineering'
  AND salary > 95000
  AND age < 35;
```

---

### Query 3: Aggregations

**Count employees per department:**
```sql
SELECT department, COUNT(*) as num_employees
FROM employees
GROUP BY department;
```

**What happens (MapReduce in action!):**

```
MAP Phase:
  Read: [Engineering, John], [Sales, Jane], [Engineering, Mike]...
  Emit: (Engineering, 1), (Sales, 1), (Engineering, 1)...

SHUFFLE:
  Group: Engineering → [1, 1, 1, 1]
         Sales → [1, 1, 1]
         Marketing → [1, 1]

REDUCE Phase:
  Engineering: SUM([1,1,1,1]) = 4
  Sales: SUM([1,1,1]) = 3
  Marketing: SUM([1,1]) = 2
```

**Expected output:**
```
OK
Engineering     4
Marketing       2
Sales           3
Time taken: 12.456 seconds, Fetched: 3 row(s)
```

**Why 12 seconds?** Full MapReduce job with shuffle/reduce phase!

---

### Query 4: Multiple Aggregations

```sql
SELECT
  department,
  COUNT(*) as employee_count,
  AVG(salary) as avg_salary,
  MAX(salary) as max_salary,
  MIN(salary) as min_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;
```

**Expected output:**
```
OK
Engineering     4       98750.0     102000.0    95000.0
Marketing       2       84500.0     85000.0     84000.0
Sales           3       75000.0     78000.0     72000.0
Time taken: 14.234 seconds, Fetched: 3 row(s)
```

**What this query does:**
1. **GROUP BY** department (shuffle phase)
2. **Aggregations** in reducers (count, avg, max, min)
3. **ORDER BY** avg_salary (requires additional sort)
4. Returns sorted results

---

### Query 5: DISTINCT Values

```sql
-- How many unique departments exist?
SELECT DISTINCT department
FROM employees;
```

**Expected output:**
```
OK
Engineering
Marketing
Sales
Time taken: 3.456 seconds, Fetched: 3 row(s)
```

**Count unique departments:**
```sql
SELECT COUNT(DISTINCT department) as unique_depts
FROM employees;
```

---

## Advanced Queries

### Query 6: String Functions

```sql
-- Employees whose name starts with 'J'
SELECT name, department
FROM employees
WHERE name LIKE 'J%';
```

**Common string functions:**
```sql
SELECT
  name,
  UPPER(name) as uppercase_name,
  LOWER(department) as lowercase_dept,
  LENGTH(name) as name_length,
  CONCAT(department, ' - ', name) as full_info
FROM employees
LIMIT 5;
```

**Expected output:**
```
OK
John Smith      JOHN SMITH      engineering     10      Engineering - John Smith
Jane Doe        JANE DOE        sales           8       Sales - Jane Doe
...
```

---

### Query 7: CASE Statements

**Categorize employees by salary:**
```sql
SELECT
  name,
  salary,
  CASE
    WHEN salary > 95000 THEN 'Senior'
    WHEN salary > 80000 THEN 'Mid-Level'
    ELSE 'Junior'
  END as salary_grade
FROM employees;
```

**Expected output:**
```
OK
John Smith      95000.0     Mid-Level
Mike Johnson    102000.0    Senior
Sarah Williams  85000.0     Mid-Level
Tom Brown       72000.0     Junior
...
```

---

### Query 8: Subqueries

**Find employees earning above department average:**
```sql
SELECT
  e.name,
  e.department,
  e.salary,
  dept_avg.avg_sal as dept_average
FROM employees e
JOIN (
  SELECT department, AVG(salary) as avg_sal
  FROM employees
  GROUP BY department
) dept_avg
ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_sal;
```

**What happens:**
1. Inner query calculates average per department
2. Join with original table
3. Filter employees above their department's average

---

### Query 9: Date Functions

```sql
-- Employees hired in 2020
SELECT name, hire_date
FROM employees
WHERE YEAR(hire_date) = 2020;
```

**Calculate tenure:**
```sql
SELECT
  name,
  hire_date,
  DATEDIFF(CURRENT_DATE(), hire_date) as days_employed,
  ROUND(DATEDIFF(CURRENT_DATE(), hire_date) / 365, 1) as years_employed
FROM employees;
```

---

## Performance Optimization

### Optimization 1: Enable Compression

```sql
-- Enable compression for intermediate data
SET hive.exec.compress.intermediate=true;
SET mapred.map.output.compression.codec=org.apache.hadoop.io.compress.SnappyCodec;

-- Run your query
SELECT department, COUNT(*)
FROM employees
GROUP BY department;
```

**Benefit:** Less data shuffled between map and reduce → Faster

---

### Optimization 2: Increase Reducers

```sql
-- Default: Hive auto-calculates reducer count
-- For large datasets, manually increase

SET mapreduce.job.reduces=4;

SELECT customer_id, SUM(total_spend)
FROM customers
GROUP BY customer_id;
```

**When to use:** Large datasets with many groups

---

### Optimization 3: Partition Tables

**Create partitioned table:**
```sql
CREATE TABLE employees_partitioned (
  employee_id INT,
  name STRING,
  salary DOUBLE,
  age INT,
  hire_date STRING
)
PARTITIONED BY (department STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
```

**Insert data with partitioning:**
```sql
INSERT OVERWRITE TABLE employees_partitioned PARTITION(department)
SELECT employee_id, name, salary, age, hire_date, department
FROM employees;
```

**Query specific partition (much faster!):**
```sql
-- Only scans Engineering partition, not entire table
SELECT * FROM employees_partitioned
WHERE department = 'Engineering';
```

**Directory structure in HDFS:**
```
/user/hive/warehouse/learning.db/employees_partitioned/
  ├── department=Engineering/
  │   └── data_file
  ├── department=Sales/
  │   └── data_file
  └── department=Marketing/
      └── data_file
```

**Benefit:** Queries filter partitions → Scan less data → Much faster!

---

## Monitoring Hive Queries

### Web UI Monitoring

**HiveServer2 Web UI:**
```
http://localhost:10002
```

**What you'll see:**
- Active SQL queries
- Query history
- Session information
- Configuration parameters

**YARN ResourceManager:**
```
http://localhost:8088
```

**What you'll see:**
- MapReduce jobs created by Hive
- Job progress and logs
- Resource utilization

---

### Explain Query Execution Plan

```sql
EXPLAIN
SELECT department, AVG(salary)
FROM employees
GROUP BY department;
```

**Output shows:**
```
STAGE DEPENDENCIES:
  Stage-1 is a root stage
  Stage-0 depends on stages: Stage-1

STAGE PLANS:
  Stage: Stage-1
    Map Reduce
      Map Operator Tree:
          TableScan
            alias: employees
            Statistics: Num rows: 100 Data size: 10000 bytes
            Select Operator
              expressions: department (type: string), salary (type: double)
              Group By Operator
                aggregations: sum(salary), count(salary)
                keys: department (type: string)
                mode: hash
                outputColumnNames: _col0, _col1, _col2
      Reduce Operator Tree:
        Group By Operator
          aggregations: sum(_col1), count(_col2)
          keys: _col0 (type: string)
          mode: mergepartial
          outputColumnNames: _col0, _col1, _col2
```

**Key insights from EXPLAIN:**
- Shows map and reduce phases
- Estimated rows and data size
- Operator tree (scan → select → group by → aggregate)

---

## Common Issues

### Issue 1: Table shows NULL values

**Problem:**
```sql
SELECT * FROM employees LIMIT 3;
```

**Output:**
```
NULL    NULL    NULL    NULL    NULL    NULL
NULL    NULL    NULL    NULL    NULL    NULL
NULL    NULL    NULL    NULL    NULL    NULL
```

**Cause:** Wrong delimiter or file format

**Solution:**
```sql
DROP TABLE employees;

CREATE TABLE employees (...)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','  ← Check delimiter matches file!
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");  ← Skip headers!
```

---

### Issue 2: Query very slow

**Symptom:** Simple query takes 30+ seconds

**Solutions:**

1. **Check data size:**
```sql
-- How much data are we scanning?
SELECT COUNT(*) FROM employees;
```

2. **Use LIMIT for exploration:**
```sql
-- Instead of SELECT * FROM huge_table;
SELECT * FROM huge_table LIMIT 100;
```

3. **Enable local mode for small datasets:**
```sql
SET hive.exec.mode.local.auto=true;
SET hive.exec.mode.local.auto.inputbytes.max=50000000;  -- 50MB
```

---

### Issue 3: Cannot create table

**Error:**
```
FAILED: SemanticException org.apache.hadoop.hive.ql.metadata.HiveException:
MetaException(message:Got exception: org.apache.hadoop.security.AccessControlException
Permission denied)
```

**Solution:**
```bash
# Fix HDFS permissions
docker-compose exec namenode bash
hadoop fs -chmod -R 777 /user/hive/warehouse
```

---

## Exercises

### Exercise 1: Find High Earners
```sql
-- Find employees earning more than department average
SELECT
  name,
  department,
  salary
FROM employees e
WHERE salary > (
  SELECT AVG(salary)
  FROM employees
  WHERE department = e.department
);
```

### Exercise 2: Customer Analytics
```sql
-- Find customers who spent more than $10,000
SELECT
  name,
  region,
  total_spend
FROM customers
WHERE total_spend > 10000
ORDER BY total_spend DESC;
```

### Exercise 3: Product Inventory
```sql
-- Products low on stock by category
SELECT
  category,
  COUNT(*) as low_stock_products,
  AVG(stock_quantity) as avg_stock
FROM products
WHERE stock_quantity < 50
GROUP BY category;
```

---

## Real-World Applications

### Application 1: Web Analytics
```sql
-- Daily page views by country
SELECT
  DATE(timestamp) as date,
  country,
  COUNT(*) as page_views
FROM web_logs
WHERE timestamp >= '2025-11-01'
GROUP BY DATE(timestamp), country
ORDER BY date, page_views DESC;
```

### Application 2: E-commerce Reporting
```sql
-- Monthly sales report
SELECT
  YEAR(order_date) as year,
  MONTH(order_date) as month,
  SUM(order_total) as total_revenue,
  COUNT(DISTINCT customer_id) as unique_customers,
  AVG(order_total) as avg_order_value
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;
```

### Application 3: User Retention
```sql
-- Users active in both current and previous month
SELECT COUNT(DISTINCT u1.user_id) as retained_users
FROM user_activity u1
JOIN user_activity u2
  ON u1.user_id = u2.user_id
WHERE u1.month = '2025-11'
  AND u2.month = '2025-10';
```

---

## Key Takeaways

✅ **Hive brings SQL to big data** - Analyze terabytes with familiar SQL

✅ **Hive compiles SQL to MapReduce** - You write SQL, Hive runs distributed jobs

✅ **Schema-on-read is flexible** - Load data first, define schema later

✅ **Best for batch analytics** - Not for real-time or transactional workloads

✅ **Partitioning speeds up queries** - Scan only relevant data

✅ **Monitor via web UIs** - Check HiveServer2 and YARN for query progress

---

## Hive vs Other Tools

| Tool | When to Use |
|------|-------------|
| **Hive** | Batch analytics, data warehousing, SQL users, large datasets (TB+) |
| **MapReduce** | Custom logic, complex algorithms, when SQL isn't expressive enough |
| **Spark SQL** | Same as Hive but need faster queries (in-memory processing) |
| **Impala/Presto** | Interactive analytics, sub-second queries |
| **HBase** | Real-time random access, key-value lookups |

---

## Next Steps

**You've mastered Hive SQL fundamentals!** Now you can:

1. **Move to Tutorial 04** to learn HBase (NoSQL database)
2. **Practice more queries:**
   - Try JOINs between tables
   - Create views
   - Experiment with window functions
3. **Read more:** [Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)

---

## Quick Reference

```sql
-- Connection
docker-compose exec hive-server hive

-- Database operations
SHOW DATABASES;
CREATE DATABASE mydb;
USE mydb;

-- Table operations
SHOW TABLES;
DESCRIBE tablename;
CREATE TABLE ...;
LOAD DATA INPATH '/hdfs/path' INTO TABLE tablename;

-- Queries
SELECT * FROM table LIMIT 10;
SELECT col1, COUNT(*) FROM table GROUP BY col1;
SELECT * FROM table WHERE condition;

-- Optimization
SET hive.exec.compress.intermediate=true;
SET mapreduce.job.reduces=4;

-- Monitoring
http://localhost:10002  -- HiveServer2 Web UI
http://localhost:8088   -- YARN ResourceManager

-- Exit
EXIT;
```
