# Tutorial 06: Sqoop ETL

**Duration:** 50-60 minutes
**Difficulty:** Intermediate

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What ETL is** and why moving data between systems is critical
- **How Sqoop works** - the bridge between traditional databases and Hadoop
- **Import vs Export** - moving data in both directions
- **Incremental imports** - syncing only new/changed data
- **Parallel processing** - splitting imports across multiple workers
- **Output formats** - choosing the right storage format (text, Parquet, Avro)

**Real-world relevance:** Every company has data in multiple systems - Oracle databases, MySQL, PostgreSQL, SQL Server. Sqoop is the standard tool for moving this data into Hadoop for analytics. Companies like LinkedIn, Facebook, and Netflix use Sqoop to move terabytes of production database data into their data lakes daily.

---

## Conceptual Overview: What is Sqoop?

### The Problem: Data Silos

Modern companies have data scattered across many systems:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   MySQL      │  │  PostgreSQL  │  │   Oracle     │
│              │  │              │  │              │
│ Transactions │  │ User Profiles│  │ Inventory    │
│ Orders       │  │ Preferences  │  │ Suppliers    │
└──────────────┘  └──────────────┘  └──────────────┘
       ↓                 ↓                 ↓
       ???              ???               ???
       ↓                 ↓                 ↓
┌─────────────────────────────────────────────────┐
│              Hadoop / Data Lake                 │
│  (Need all data here for analytics)             │
└─────────────────────────────────────────────────┘
```

**Challenges:**
- ❌ Each database has different formats, APIs, query languages
- ❌ Manual export/import is slow and error-prone
- ❌ Network transfers can take days for large tables
- ❌ Need to keep data synchronized (incremental updates)
- ❌ Production databases can't handle heavy analytics queries

### The Sqoop Solution

**Sqoop = SQL-to-Hadoop** - A tool that automates data transfer between relational databases and Hadoop.

```
              ┌─────────────────────────────────┐
              │        Apache Sqoop             │
              │  "The Database-Hadoop Bridge"   │
              └─────────────────────────────────┘
                        ↑         ↓
         IMPORT ────────┘         └──────── EXPORT

┌──────────────┐                    ┌──────────────┐
│   Database   │                    │     HDFS     │
│   (MySQL)    │ ←──────────────→  │ (Hadoop)     │
│              │                    │              │
│  Orders:     │    Sqoop moves:   │ /data/orders/│
│  - 10M rows  │    • Row by row   │  part-m-0000 │
│  - 5 columns │    • In parallel  │  part-m-0001 │
│  - Live data │    • Via JDBC     │  part-m-0002 │
└──────────────┘                    └──────────────┘
```

**How Sqoop works:**
1. **Connects via JDBC** (standard database protocol)
2. **Queries table metadata** (columns, types, primary keys)
3. **Launches MapReduce jobs** (parallel workers)
4. **Each mapper reads a chunk** of the table
5. **Writes to HDFS** in chosen format

**Key benefits:**
- ✅ **Automated** - one command instead of manual scripts
- ✅ **Parallel** - multiple mappers read simultaneously
- ✅ **Fault-tolerant** - MapReduce handles failures
- ✅ **Incremental** - only sync new/changed data
- ✅ **Flexible** - supports many databases and formats

---

### ETL: Extract, Transform, Load

Sqoop is an **ETL tool** - specifically, it handles **E** (Extract) and **L** (Load):

```
┌─────────────────────────────────────────────────────────────┐
│                    ETL PIPELINE                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. EXTRACT (Sqoop Import)                                  │
│     MySQL → HDFS                                            │
│     "Get data from source systems"                          │
│                                                             │
│  2. TRANSFORM (Hive/Pig/Spark)                             │
│     Clean, join, aggregate data                             │
│     "Process and enrich data"                               │
│                                                             │
│  3. LOAD (Sqoop Export or Hive/HBase)                      │
│     HDFS → Data Warehouse / Analytics DB                    │
│     "Make data available for users"                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### Sqoop vs Alternatives

| Approach | Sqoop | Manual Scripts | Flume | Kafka Connect |
|----------|-------|----------------|-------|---------------|
| **Use case** | Bulk DB import/export | Custom needs | Streaming logs | Real-time CDC |
| **Speed** | Fast (parallel) | Slow (single-threaded) | Very fast | Very fast |
| **Complexity** | Medium | High | High | High |
| **Learning curve** | Easy | Varies | Medium | Medium |
| **Best for** | Batch database sync | One-off tasks | Log aggregation | Real-time sync |
| **Incremental** | Yes (append/lastmod) | Manual logic | N/A | Native CDC |

**When to use Sqoop:**
- Importing entire database tables to HDFS
- Nightly/hourly batch imports from production DBs
- One-time data migration to Hadoop
- Exporting analytics results back to databases

**When NOT to use Sqoop:**
- Real-time streaming data → Use Kafka/Flume
- Log files → Use Flume or direct HDFS write
- Small datasets → Manual copy might be simpler
- NoSQL databases → Use database-specific tools

---

### Sqoop Architecture Deep Dive

```
┌─────────────────────────────────────────────────────────────┐
│  YOU (Data Engineer)                                        │
│  Runs: sqoop import --table employees ...                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  SQOOP CLIENT                                               │
│  1. Parses command-line arguments                           │
│  2. Connects to database via JDBC                           │
│  3. Queries table metadata: SELECT * FROM employees LIMIT 1 │
│  4. Determines split strategy (based on --split-by)         │
│  5. Generates MapReduce job                                 │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  MAPREDUCE JOB (on YARN)                                    │
│                                                             │
│  Mapper 1:          Mapper 2:          Mapper 3:           │
│  SELECT * FROM      SELECT * FROM      SELECT * FROM       │
│  employees WHERE    employees WHERE    employees WHERE     │
│  id BETWEEN         id BETWEEN         id BETWEEN          │
│  1 AND 333          334 AND 666        667 AND 1000        │
│                                                             │
│  ↓ Reads rows       ↓ Reads rows       ↓ Reads rows        │
│  ↓ Converts format  ↓ Converts format  ↓ Converts format   │
│  ↓ Writes to HDFS   ↓ Writes to HDFS   ↓ Writes to HDFS    │
└────────────────┬────────────┬───────────┬───────────────────┘
                 │            │           │
                 ▼            ▼           ▼
┌─────────────────────────────────────────────────────────────┐
│  HDFS                                                       │
│  /user/sqoop/employees/                                     │
│    part-m-00000  (rows 1-333)                              │
│    part-m-00001  (rows 334-666)                            │
│    part-m-00002  (rows 667-1000)                           │
│    _SUCCESS                                                 │
└─────────────────────────────────────────────────────────────┘

Key insight: Each mapper runs a SQL query in parallel!
```

**Why is this fast?**
- **Parallel reads**: 4 mappers → 4x faster than single connection
- **Database splits query load**: Read requests distributed across DB
- **Direct JDBC**: No intermediate files or staging
- **MapReduce fault tolerance**: Failures auto-retry

---

## Prerequisites

Before starting, ensure:
```bash
# Check that your cluster is running
docker-compose ps

# You should see these services as "Up":
# - namenode (Hadoop)
# - mariadb (MySQL database)
# - resourcemanager (YARN)
# - nodemanager (YARN)
```

If services aren't running:
```bash
cd /Users/jason/Files/Practice/demo-little-things/hadoop-tutorial
docker-compose up -d
```

---

## Hands-On Exercises

### Exercise 1: Verify Database Connection

**What we're doing:** Ensuring Sqoop can connect to MariaDB (MySQL-compatible).

```bash
# Connect to NameNode container (where Sqoop is installed)
docker-compose exec namenode bash
```

**Test database connectivity:**
```bash
sqoop list-databases \
  --connect jdbc:mysql://mariadb:3306 \
  --username root \
  --password root
```

**Expected output:**
```
Warning: /opt/sqoop/../hbase does not exist! HBase imports will fail.
...
information_schema
hive_metastore
mysql
performance_schema
test
```

**What just happened:**
```
Step 1: Sqoop loaded MySQL JDBC driver
        └─ /opt/sqoop/lib/mysql-connector-java.jar

Step 2: Connected to MariaDB
        └─ JDBC URL: jdbc:mysql://mariadb:3306

Step 3: Executed: SHOW DATABASES;

Step 4: Returned list of available databases
```

**If this fails:**
- Check `docker-compose ps` - is mariadb running?
- Check network: `ping mariadb` inside container
- Verify credentials: `-u root -p root` works in MariaDB CLI

---

### Exercise 2: Create Sample Data in MySQL

**Concept:** Setting up a test database table to import.

**Connect to MariaDB:**
```bash
# Open a new terminal window
docker-compose exec mariadb mysql -u root -proot
```

**Create test database and table:**
```sql
-- Create database
CREATE DATABASE IF NOT EXISTS company;
USE company;

-- Create employees table
CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name VARCHAR(100),
  department VARCHAR(50),
  salary DECIMAL(10, 2),
  age INT,
  hire_date DATE
);

-- Insert sample data
INSERT INTO employees VALUES
  (1, 'Alice Smith', 'Engineering', 95000.00, 28, '2020-01-15'),
  (2, 'Bob Johnson', 'Marketing', 75000.00, 35, '2019-06-20'),
  (3, 'Carol Williams', 'Engineering', 85000.00, 31, '2021-03-10'),
  (4, 'David Brown', 'Sales', 70000.00, 29, '2020-08-05'),
  (5, 'Eve Davis', 'Engineering', 105000.00, 42, '2018-02-14'),
  (6, 'Frank Miller', 'Marketing', 68000.00, 26, '2022-01-20'),
  (7, 'Grace Wilson', 'Sales', 72000.00, 33, '2019-11-30'),
  (8, 'Henry Moore', 'Engineering', 92000.00, 37, '2020-05-18'),
  (9, 'Ivy Taylor', 'Marketing', 78000.00, 30, '2021-07-22'),
  (10, 'Jack Anderson', 'Sales', 88000.00, 45, '2017-09-08');

-- Verify data
SELECT * FROM employees;
```

**Expected output:**
```
+-------------+----------------+-------------+----------+------+------------+
| employee_id | name           | department  | salary   | age  | hire_date  |
+-------------+----------------+-------------+----------+------+------------+
|           1 | Alice Smith    | Engineering | 95000.00 |   28 | 2020-01-15 |
|           2 | Bob Johnson    | Marketing   | 75000.00 |   35 | 2019-06-20 |
|           3 | Carol Williams | Engineering | 85000.00 |   31 | 2021-03-10 |
...
+-------------+----------------+-------------+----------+------+------------+
10 rows in set (0.00 sec)
```

**Exit MySQL:**
```sql
EXIT;
```

---

### Exercise 3: List Available Tables

**Concept:** Discovering what tables exist in the database.

**Back in the NameNode container:**
```bash
sqoop list-tables \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root
```

**Expected output:**
```
Warning: /opt/sqoop/../hbase does not exist! HBase imports will fail.
...
employees
```

**What this does:**
- Connects to `company` database
- Executes `SHOW TABLES;`
- Lists all available tables

---

### Exercise 4: Preview Table Data

**Concept:** Inspecting table contents before full import.

```bash
sqoop eval \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --query "SELECT * FROM employees LIMIT 3"
```

**Expected output:**
```
----------------------------------------------------------------------------------
| employee_id | name          | department  | salary    | age | hire_date  |
----------------------------------------------------------------------------------
| 1           | Alice Smith   | Engineering | 95000.00  | 28  | 2020-01-15 |
| 2           | Bob Johnson   | Marketing   | 75000.00  | 35  | 2019-06-20 |
| 3           | Carol Williams| Engineering | 85000.00  | 31  | 2021-03-10 |
----------------------------------------------------------------------------------
```

**What just happened:**
- `sqoop eval` executes arbitrary SQL queries
- Useful for testing queries before imports
- Data stays in database (not imported)

---

### Exercise 5: Basic Import (Complete Table)

**Concept:** Importing an entire table to HDFS.

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees \
  --delete-target-dir \
  --num-mappers 1
```

**Expected output (abbreviated):**
```
Warning: /opt/sqoop/../hbase does not exist! HBase imports will fail.
...
25/11/15 10:00:00 INFO sqoop.Sqoop: Running Sqoop version: 1.4.7
25/11/15 10:00:01 INFO manager.MySQLManager: Preparing to use a MySQL streaming resultset.
25/11/15 10:00:01 INFO tool.CodeGenTool: Beginning code generation
25/11/15 10:00:02 INFO manager.SqlManager: Executing SQL statement: SELECT t.* FROM `employees` AS t LIMIT 1
25/11/15 10:00:02 INFO orm.CompilationManager: Writing jar file: /tmp/sqoop-hadoop/compile/...
25/11/15 10:00:03 INFO mapreduce.ImportJobBase: Beginning import of employees
25/11/15 10:00:05 INFO mapreduce.Job: Running job: job_1731668400003_0001
...
25/11/15 10:00:45 INFO mapreduce.Job: Job job_1731668400003_0001 completed successfully
25/11/15 10:00:45 INFO mapreduce.ImportJobBase: Transferred 1.0 KB in 42 seconds (24 bytes/sec)
25/11/15 10:00:45 INFO mapreduce.ImportJobBase: Retrieved 10 records.
```

**Let's decode the parameters:**
```bash
--connect jdbc:mysql://mariadb:3306/company
  └─ Database connection string
     jdbc:mysql://  → Protocol
     mariadb:3306   → Host:Port (Docker service name)
     /company       → Database name

--username root --password root
  └─ Database credentials (in production, use --password-file)

--table employees
  └─ Table to import (must exist in database)

--target-dir /user/sqoop/employees
  └─ HDFS destination directory

--delete-target-dir
  └─ Delete directory if it exists (prevents errors on re-run)

--num-mappers 1
  └─ Number of parallel mappers (1 = single mapper, no splitting)
```

**Verify the import:**
```bash
# List output files
hadoop fs -ls /user/sqoop/employees/
```

**Expected output:**
```
Found 2 items
-rw-r--r--   2 hadoop supergroup          0 2025-11-15 10:00 /user/sqoop/employees/_SUCCESS
-rw-r--r--   2 hadoop supergroup       1024 2025-11-15 10:00 /user/sqoop/employees/part-m-00000
```

**View the data:**
```bash
hadoop fs -cat /user/sqoop/employees/part-m-00000
```

**Expected output:**
```
1,Alice Smith,Engineering,95000.00,28,2020-01-15
2,Bob Johnson,Marketing,75000.00,35,2019-06-20
3,Carol Williams,Engineering,85000.00,31,2021-03-10
4,David Brown,Sales,70000.00,29,2020-08-05
5,Eve Davis,Engineering,105000.00,42,2018-02-14
6,Frank Miller,Marketing,68000.00,26,2022-01-20
7,Grace Wilson,Sales,72000.00,33,2019-11-30
8,Henry Moore,Engineering,92000.00,37,2020-05-18
9,Ivy Taylor,Marketing,78000.00,30,2021-07-22
10,Jack Anderson,Sales,88000.00,45,2017-09-08
```

**What just happened (detailed flow):**

```
Step 1: METADATA INSPECTION
  Sqoop: SELECT t.* FROM employees AS t LIMIT 1
  MySQL: Returns columns → employee_id, name, department, salary, age, hire_date
  Sqoop: Generates Java code to map DB types to Hadoop types

Step 2: CODE GENERATION
  Creates: employees.java
  Compiles: employees.jar
  Purpose: Serialize/deserialize database rows

Step 3: MAPREDUCE LAUNCH
  YARN: Allocates 1 mapper (--num-mappers 1)
  Mapper receives: Connection info + table name

Step 4: DATA TRANSFER
  Mapper: SELECT * FROM employees
  MySQL: Streams all 10 rows
  Mapper: Converts each row to CSV format
  Mapper: Writes to HDFS: part-m-00000

Step 5: COMPLETION
  Writes _SUCCESS file (indicates complete job)
  Reports: 10 records, 1.0 KB transferred
```

---

### Exercise 6: Parallel Import (Multiple Mappers)

**Concept:** Splitting table across multiple mappers for faster import.

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_parallel \
  --delete-target-dir \
  --num-mappers 4 \
  --split-by employee_id
```

**Expected output (key differences):**
```
...
25/11/15 10:05:00 INFO mapreduce.Job: Running job: job_1731668400003_0002
25/11/15 10:05:05 INFO mapreduce.Job:  map 0% reduce 0%
25/11/15 10:05:15 INFO mapreduce.Job:  map 25% reduce 0%
25/11/15 10:05:18 INFO mapreduce.Job:  map 50% reduce 0%
25/11/15 10:05:20 INFO mapreduce.Job:  map 75% reduce 0%
25/11/15 10:05:22 INFO mapreduce.Job:  map 100% reduce 0%
...
25/11/15 10:05:25 INFO mapreduce.ImportJobBase: Retrieved 10 records.
```

**Verify the import:**
```bash
hadoop fs -ls /user/sqoop/employees_parallel/
```

**Expected output:**
```
Found 5 items
-rw-r--r--   2 hadoop supergroup          0 2025-11-15 10:05 /user/sqoop/employees_parallel/_SUCCESS
-rw-r--r--   2 hadoop supergroup        256 2025-11-15 10:05 /user/sqoop/employees_parallel/part-m-00000
-rw-r--r--   2 hadoop supergroup        256 2025-11-15 10:05 /user/sqoop/employees_parallel/part-m-00001
-rw-r--r--   2 hadoop supergroup        256 2025-11-15 10:05 /user/sqoop/employees_parallel/part-m-00002
-rw-r--r--   2 hadoop supergroup        256 2025-11-15 10:05 /user/sqoop/employees_parallel/part-m-00003
```

**View each part:**
```bash
hadoop fs -cat /user/sqoop/employees_parallel/part-m-00000
```

**What happened (parallel split):**

```
--num-mappers 4 + --split-by employee_id

Step 1: Sqoop queries min/max of employee_id
  SELECT MIN(employee_id), MAX(employee_id) FROM employees
  Result: min=1, max=10

Step 2: Calculate split ranges (10 rows / 4 mappers = 2.5 rows each)
  Mapper 0: employee_id >= 1  AND employee_id < 3   (rows 1-2)
  Mapper 1: employee_id >= 3  AND employee_id < 6   (rows 3-5)
  Mapper 2: employee_id >= 6  AND employee_id < 9   (rows 6-8)
  Mapper 3: employee_id >= 9  AND employee_id <= 10 (rows 9-10)

Step 3: Each mapper runs in parallel:
  Mapper 0: SELECT * FROM employees WHERE employee_id >= 1 AND employee_id < 3
  Mapper 1: SELECT * FROM employees WHERE employee_id >= 3 AND employee_id < 6
  Mapper 2: SELECT * FROM employees WHERE employee_id >= 6 AND employee_id < 9
  Mapper 3: SELECT * FROM employees WHERE employee_id >= 9 AND employee_id <= 10

Step 4: Write to separate files
  part-m-00000 ← Mapper 0
  part-m-00001 ← Mapper 1
  part-m-00002 ← Mapper 2
  part-m-00003 ← Mapper 3
```

**Why use multiple mappers?**
- ✅ **Faster imports**: 4 mappers → up to 4x speedup
- ✅ **Database load distribution**: Queries run in parallel
- ✅ **Network utilization**: Multiple connections saturate bandwidth

**Important notes about --split-by:**
- Must be a numeric column (int, bigint, etc.)
- Should have even distribution (not all values clustered)
- Primary key or indexed column works best
- **Without --split-by**: Sqoop uses primary key automatically

---

### Exercise 7: Filtered Import (WHERE Clause)

**Concept:** Importing only specific rows that match criteria.

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --where "salary > 80000" \
  --target-dir /user/sqoop/high_earners \
  --delete-target-dir \
  --num-mappers 1
```

**Expected output:**
```
...
25/11/15 10:10:00 INFO mapreduce.ImportJobBase: Retrieved 5 records.
```

**View the data:**
```bash
hadoop fs -cat /user/sqoop/high_earners/part-m-00000
```

**Expected output (only high earners):**
```
1,Alice Smith,Engineering,95000.00,28,2020-01-15
3,Carol Williams,Engineering,85000.00,31,2021-03-10
5,Eve Davis,Engineering,105000.00,42,2018-02-14
8,Henry Moore,Engineering,92000.00,37,2020-05-18
10,Jack Anderson,Sales,88000.00,45,2017-09-08
```

**What happened:**
```
Step 1: Sqoop generates SQL query
  SELECT * FROM employees WHERE salary > 80000

Step 2: Mapper executes query and retrieves 5 rows

Step 3: Writes filtered data to HDFS
```

**Use cases:**
- Import only recent data: `--where "hire_date > '2020-01-01'"`
- Import specific department: `--where "department = 'Engineering'"`
- Import active records: `--where "status = 'active'"`

---

### Exercise 8: Column Selection

**Concept:** Importing only specific columns (projection).

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --columns "name,department,salary" \
  --target-dir /user/sqoop/employees_subset \
  --delete-target-dir \
  --num-mappers 1
```

**View the data:**
```bash
hadoop fs -cat /user/sqoop/employees_subset/part-m-00000
```

**Expected output (only 3 columns):**
```
Alice Smith,Engineering,95000.00
Bob Johnson,Marketing,75000.00
Carol Williams,Engineering,85000.00
David Brown,Sales,70000.00
Eve Davis,Engineering,105000.00
Frank Miller,Marketing,68000.00
Grace Wilson,Sales,72000.00
Henry Moore,Engineering,92000.00
Ivy Taylor,Marketing,78000.00
Jack Anderson,Sales,88000.00
```

**What happened:**
```
Sqoop generated: SELECT name, department, salary FROM employees

Benefits:
  - Smaller file size (3 columns vs 6)
  - Faster transfer (less data over network)
  - Privacy (exclude sensitive columns like employee_id)
```

---

### Exercise 9: Custom Field Delimiters

**Concept:** Changing output format (tab-separated instead of comma).

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_tsv \
  --delete-target-dir \
  --num-mappers 1 \
  --fields-terminated-by '\t' \
  --lines-terminated-by '\n'
```

**View the data:**
```bash
hadoop fs -cat /user/sqoop/employees_tsv/part-m-00000 | head -3
```

**Expected output (tab-separated):**
```
1	Alice Smith	Engineering	95000.00	28	2020-01-15
2	Bob Johnson	Marketing	75000.00	35	2019-06-20
3	Carol Williams	Engineering	85000.00	31	2021-03-10
```

**Common delimiter options:**
```bash
--fields-terminated-by ','   # CSV (default)
--fields-terminated-by '\t'  # TSV (tab-separated)
--fields-terminated-by '|'   # Pipe-separated
--fields-terminated-by '\001' # Hive default (Ctrl-A character)

--lines-terminated-by '\n'   # Unix newline (default)
--lines-terminated-by '\r\n' # Windows newline
```

**Why this matters:**
- Hive uses `\001` (Ctrl-A) by default
- Some tools expect specific formats
- Avoids issues when data contains commas

---

### Exercise 10: Incremental Import (Append Mode)

**Concept:** Importing only new rows added since last import.

**First, add more data to the database:**
```bash
# Connect to MariaDB
docker-compose exec mariadb mysql -u root -proot company

# Add new employees
INSERT INTO employees VALUES
  (11, 'Karen Lee', 'Engineering', 98000.00, 29, '2023-01-10'),
  (12, 'Leo Chen', 'Sales', 73000.00, 34, '2023-02-15'),
  (13, 'Mia Rodriguez', 'Marketing', 81000.00, 27, '2023-03-20');

SELECT * FROM employees WHERE employee_id > 10;
EXIT;
```

**Initial import (baseline):**
```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_incremental \
  --delete-target-dir \
  --num-mappers 1 \
  --check-column employee_id \
  --incremental append \
  --last-value 0
```

**Expected output:**
```
...
25/11/15 10:15:00 INFO mapreduce.ImportJobBase: Retrieved 13 records.
...
--incremental append
  --check-column employee_id
  --last-value 0
(Consider saving this with 'sqoop job' to simplify execution)
```

**Important output - save the last value:**
```
--last-value 13  ← This is the max employee_id imported
```

**View the data:**
```bash
hadoop fs -cat /user/sqoop/employees_incremental/part-m-00000
```

**Now add more employees:**
```bash
docker-compose exec mariadb mysql -u root -proot company -e "
  INSERT INTO employees VALUES
    (14, 'Noah Garcia', 'Finance', 92000.00, 38, '2023-04-10'),
    (15, 'Olivia Martinez', 'Engineering', 103000.00, 33, '2023-05-05');
"
```

**Incremental import (only new rows):**
```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table employees \
  --target-dir /user/sqoop/employees_incremental \
  --num-mappers 1 \
  --check-column employee_id \
  --incremental append \
  --last-value 13
```

**Expected output:**
```
...
25/11/15 10:20:00 INFO tool.ImportTool: Incremental import based on column employee_id
25/11/15 10:20:00 INFO tool.ImportTool: Lower bound value: 13
...
25/11/15 10:20:15 INFO mapreduce.ImportJobBase: Retrieved 2 records.
...
--last-value 15  ← Updated max value
```

**View the new data:**
```bash
hadoop fs -ls /user/sqoop/employees_incremental/
hadoop fs -cat /user/sqoop/employees_incremental/part-m-00001
```

**Expected output:**
```
14,Noah Garcia,Finance,92000.00,38,2023-04-10
15,Olivia Martinez,Engineering,103000.00,33,2023-05-05
```

**What happened:**

```
First import (--last-value 0):
  SQL: SELECT * FROM employees WHERE employee_id > 0
  Result: All 13 rows → part-m-00000
  Sqoop reports: --last-value 13

Second import (--last-value 13):
  SQL: SELECT * FROM employees WHERE employee_id > 13
  Result: Only 2 new rows (14, 15) → part-m-00001
  Sqoop reports: --last-value 15

Directory now contains:
  part-m-00000  (original 13 rows)
  part-m-00001  (new 2 rows)
```

**Incremental import modes:**
```bash
--incremental append
  └─ For tables that only grow (new rows, never updated)
  └─ Uses: WHERE check_column > last_value

--incremental lastmodified
  └─ For tables with updates (tracks timestamp column)
  └─ Uses: WHERE lastmod_column > last_value_timestamp
```

**Real-world usage:**
```bash
# Daily cron job for syncing orders
0 2 * * * sqoop import \
  --connect jdbc:mysql://db.company.com/sales \
  --table orders \
  --target-dir /data/orders \
  --check-column order_id \
  --incremental append \
  --last-value $(cat /var/lib/sqoop/last_order_id)
```

---

### Exercise 11: Export from HDFS to MySQL

**Concept:** Moving processed data from Hadoop back to a database.

**Create destination table in MySQL:**
```bash
docker-compose exec mariadb mysql -u root -proot company -e "
  CREATE TABLE high_earners_export (
    employee_id INT,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    age INT,
    hire_date DATE
  );
"
```

**Export from HDFS to MySQL:**
```bash
sqoop export \
  --connect jdbc:mysql://mariadb:3306/company \
  --username root \
  --password root \
  --table high_earners_export \
  --export-dir /user/sqoop/high_earners \
  --input-fields-terminated-by ','
```

**Expected output:**
```
...
25/11/15 10:25:00 INFO mapreduce.ExportJobBase: Transferred 512 bytes in 15 seconds (34 bytes/sec)
25/11/15 10:25:00 INFO mapreduce.ExportJobBase: Exported 5 records.
```

**Verify in MySQL:**
```bash
docker-compose exec mariadb mysql -u root -proot company -e "
  SELECT * FROM high_earners_export;
"
```

**Expected output:**
```
+-------------+----------------+-------------+----------+------+------------+
| employee_id | name           | department  | salary   | age  | hire_date  |
+-------------+----------------+-------------+----------+------+------------+
|           1 | Alice Smith    | Engineering | 95000.00 |   28 | 2020-01-15 |
|           3 | Carol Williams | Engineering | 85000.00 |   31 | 2021-03-10 |
|           5 | Eve Davis      | Engineering |105000.00 |   42 | 2018-02-14 |
|           8 | Henry Moore    | Engineering | 92000.00 |   37 | 2020-05-18 |
|          10 | Jack Anderson  | Sales       | 88000.00 |   45 | 2017-09-08 |
+-------------+----------------+-------------+----------+------+------------+
```

**What happened:**

```
Step 1: Sqoop reads HDFS files
  /user/sqoop/high_earners/part-m-00000

Step 2: Launches MapReduce job
  Mappers parse CSV format
  Convert to SQL INSERT statements

Step 3: Execute INSERTs
  INSERT INTO high_earners_export VALUES (1, 'Alice Smith', ...)
  INSERT INTO high_earners_export VALUES (3, 'Carol Williams', ...)
  ...

Step 4: Reports completion
  5 records exported
```

**Export modes:**
```bash
--update-mode allowinsert  # INSERT new rows, UPDATE existing
--update-mode updateonly   # Only UPDATE, never INSERT
```

---

## Real-World Applications

### Example 1: Daily Data Lake Sync

**Scenario:** E-commerce company syncs production MySQL to Hadoop nightly.

```bash
#!/bin/bash
# daily_import.sh - Run via cron at 2 AM

LAST_ORDER_ID=$(cat /var/lib/sqoop/last_order_id 2>/dev/null || echo 0)

sqoop import \
  --connect jdbc:mysql://prod-db.company.com/ecommerce \
  --username readonly_user \
  --password-file /secure/db_password.txt \
  --table orders \
  --target-dir /datalake/raw/orders \
  --check-column order_id \
  --incremental append \
  --last-value $LAST_ORDER_ID \
  --num-mappers 8 \
  --split-by order_id \
  --compress \
  --compression-codec snappy

# Save new last_value for next run
echo $NEW_LAST_VALUE > /var/lib/sqoop/last_order_id
```

**What this achieves:**
- ✅ **Minimal impact**: Runs during low-traffic hours
- ✅ **Fast**: 8 parallel mappers
- ✅ **Efficient**: Only imports new orders
- ✅ **Compressed**: Saves 70-80% storage with Snappy

---

### Example 2: Analytics Results Export

**Scenario:** Export Hive query results to reporting database.

```bash
# Step 1: Run analytics in Hive
hive -e "
  CREATE TABLE top_customers AS
  SELECT customer_id, customer_name, total_spend
  FROM (
    SELECT c.customer_id, c.name as customer_name, SUM(o.amount) as total_spend
    FROM orders o JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
  ) ranked
  ORDER BY total_spend DESC
  LIMIT 1000;
"

# Step 2: Export to MySQL for BI tool
sqoop export \
  --connect jdbc:mysql://reporting-db:3306/analytics \
  --table top_customers \
  --export-dir /user/hive/warehouse/top_customers \
  --input-fields-terminated-by '\001' \
  --num-mappers 4
```

---

### Example 3: Multi-Table Import

**Scenario:** Import entire database schema.

```bash
#!/bin/bash
# import_all_tables.sh

TABLES="orders customers products inventory shipments"

for table in $TABLES; do
  echo "Importing $table..."
  sqoop import \
    --connect jdbc:mysql://prod-db:3306/warehouse \
    --username etl_user \
    --password-file /secure/db_pass.txt \
    --table $table \
    --target-dir /datalake/raw/$table \
    --delete-target-dir \
    --num-mappers 4 \
    --compress
done

echo "All tables imported successfully"
```

---

## Common Patterns and Best Practices

### Pattern 1: Secure Password Handling

**❌ Bad (password in command):**
```bash
sqoop import ... --password root  # Visible in logs!
```

**✅ Good (password file):**
```bash
# Create password file (once)
echo -n "root" > /secure/db_password.txt
hdfs dfs -put /secure/db_password.txt /user/hadoop/
hdfs dfs -chmod 400 /user/hadoop/db_password.txt

# Use in Sqoop
sqoop import ... --password-file /user/hadoop/db_password.txt
```

---

### Pattern 2: Choosing the Right Split Column

**❌ Bad (uneven distribution):**
```bash
--split-by status  # If 99% rows have status='active', very uneven!
```

**✅ Good (even distribution):**
```bash
--split-by order_id  # Primary key, auto-increment, evenly distributed
```

**Best split-by candidates:**
- Primary key (auto-increment integer)
- Timestamp column (if evenly distributed)
- Hash of string column (for non-numeric keys)

---

### Pattern 3: Output Format Selection

**Text (default):**
```bash
--as-textfile  # Good for: Human-readable, Hive external tables
```

**Parquet (columnar):**
```bash
--as-parquetfile  # Good for: Analytics queries, 70% compression
```

**Avro (schema evolution):**
```bash
--as-avrodatafile  # Good for: Schema changes, binary efficiency
```

---

## Key Takeaways

✅ **Sqoop is the database-Hadoop bridge** - automated bulk data transfer

✅ **Uses MapReduce for parallelism** - multiple mappers read simultaneously

✅ **Import = DB → HDFS, Export = HDFS → DB** - bidirectional data flow

✅ **Incremental imports save time** - only sync new/changed data

✅ **Split-by column matters** - determines parallel efficiency

✅ **Multiple output formats** - text, Parquet, Avro, SequenceFile

✅ **Production requires planning** - passwords, scheduling, monitoring

---

## Common Issues and Solutions

### Issue 1: "No primary key could be found for table"

**Error message:**
```
ERROR tool.ImportTool: Error during import: No primary key could be found for table employees.
Please specify one with --split-by or perform a sequential import with '-m 1'.
```

**What's wrong:** Table has no primary key, Sqoop can't split for parallel import.

**Solution:**
```bash
# Option 1: Use single mapper
sqoop import ... --num-mappers 1

# Option 2: Specify split column manually
sqoop import ... --split-by employee_id
```

---

### Issue 2: "Cannot create target directory"

**Error message:**
```
ERROR tool.ImportTool: Import failed: org.apache.hadoop.mapred.FileAlreadyExistsException:
Output directory hdfs://namenode:9000/user/sqoop/employees already exists
```

**Solution:**
```bash
# Option 1: Delete existing directory
hadoop fs -rm -r /user/sqoop/employees

# Option 2: Use --delete-target-dir flag
sqoop import ... --delete-target-dir

# Option 3: Use different directory
sqoop import ... --target-dir /user/sqoop/employees_v2
```

---

### Issue 3: "Communications link failure"

**Error message:**
```
ERROR manager.SqlManager: Error executing statement: com.mysql.jdbc.exceptions.jdbc4.CommunicationsException:
Communications link failure
```

**Troubleshooting:**
```bash
# Test database connectivity
docker-compose exec namenode ping mariadb

# Test MySQL connection
docker-compose exec namenode mysql -h mariadb -u root -proot -e "SELECT 1"

# Check if MariaDB is running
docker-compose ps mariadb
```

---

## Quick Reference Card

```bash
# ==================
# IMPORT COMMANDS
# ==================

# Basic import
sqoop import \
  --connect jdbc:mysql://host:3306/database \
  --username user \
  --password-file /path/to/password \
  --table table_name \
  --target-dir /hdfs/path

# Parallel import
sqoop import ... \
  --num-mappers 4 \
  --split-by id_column

# Filtered import
sqoop import ... \
  --where "created_date > '2023-01-01'"

# Column selection
sqoop import ... \
  --columns "id,name,email"

# Incremental import
sqoop import ... \
  --check-column id \
  --incremental append \
  --last-value 1000

# ==================
# EXPORT COMMANDS
# ==================

# Basic export
sqoop export \
  --connect jdbc:mysql://host:3306/database \
  --username user \
  --password-file /path/to/password \
  --table table_name \
  --export-dir /hdfs/path \
  --input-fields-terminated-by ','

# ==================
# OUTPUT FORMATS
# ==================
--as-textfile        # Plain text (default)
--as-parquetfile     # Parquet columnar
--as-avrodatafile    # Avro binary
--as-sequencefile    # Hadoop SequenceFile

# ==================
# COMPRESSION
# ==================
--compress \
--compression-codec org.apache.hadoop.io.compress.GzipCodec

# ==================
# UTILITY COMMANDS
# ==================

# List databases
sqoop list-databases --connect jdbc:mysql://host:3306 ...

# List tables
sqoop list-tables --connect jdbc:mysql://host:3306/database ...

# Run query
sqoop eval --connect jdbc:mysql://host:3306/database ... \
  --query "SELECT COUNT(*) FROM table"
```

---

## Next Steps

**You've mastered Sqoop ETL!** Now you can:

1. **Move to Tutorial 07** to learn Advanced MapReduce techniques
2. **Experiment more:**
   ```bash
   # Try importing with different formats
   sqoop import ... --as-parquetfile

   # Set up an incremental import job
   # Export Hive query results to MySQL
   ```
3. **Learn more:**
   - Official Sqoop User Guide: https://sqoop.apache.org/docs/1.4.7/SqoopUserGuide.html
   - Explore Sqoop jobs (saving import configs)
   - Try importing from PostgreSQL, Oracle

---

**Exit container:** Type `exit` and press Enter
