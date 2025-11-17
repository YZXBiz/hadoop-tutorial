# Tutorial 05: Pig Scripts

**Duration:** 45-60 minutes
**Difficulty:** Intermediate

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What Apache Pig is** and why it exists (bridging the gap between SQL and MapReduce)
- **Pig Latin syntax** - a data flow language that's easier than Java but more flexible than SQL
- **How data transformations work** - step-by-step processing pipelines
- **When to use Pig** vs Hive vs MapReduce
- **How to write ETL scripts** for real-world data cleaning and analysis

**Real-world relevance:** Companies like Yahoo (where Pig was created), Twitter, and LinkedIn use Pig to process massive datasets with scripts that are 10x shorter than equivalent MapReduce code. Pig handles ~40% of all Yahoo Hadoop jobs.

---

## Conceptual Overview: What is Apache Pig?

### The Problem Pig Solves

Imagine you need to process web logs to find the most common error codes. Here are your options:

**Option 1: Write MapReduce (Tutorial 02 style)**
```java
// 200+ lines of Java code
public class LogAnalyzer extends Mapper { ... }
public class LogReducer extends Reducer { ... }
// Driver class, configuration, etc.
```
**Problems:**
- Takes hours/days to write
- Requires Java expertise
- Hard to read and maintain
- Fixed processing pipeline

**Option 2: Use Hive SQL (Tutorial 03 style)**
```sql
SELECT error_code, COUNT(*) as count
FROM logs
GROUP BY error_code
ORDER BY count DESC;
```
**Problems:**
- Works great for SQL-like queries
- But what if you need complex custom logic?
- What if data format is non-standard (not CSV/JSON)?
- Limited procedural control

**Option 3: Use Pig Latin**
```pig
logs = LOAD '/logs/access_logs.txt' USING PigStorage(' ');
errors = FILTER logs BY $6 >= 400;  -- Status code in column 6
by_code = GROUP errors BY $6;
counts = FOREACH by_code GENERATE group, COUNT(errors);
sorted = ORDER counts BY $1 DESC;
STORE sorted INTO '/output/error_counts';
```

**Benefits:**
- ✅ **10 lines vs 200+** (much shorter than MapReduce)
- ✅ **More flexible than SQL** (procedural, step-by-step transformations)
- ✅ **Handles any data format** (custom parsers, complex nested structures)
- ✅ **Extensible with UDFs** (User Defined Functions in Java/Python)
- ✅ **Automatic optimization** (Pig compiles to efficient MapReduce)

---

### What is Pig Latin?

**Pig Latin is a data flow language.** Unlike SQL (declarative) or Java (imperative), Pig describes how data flows through transformations:

```
Input Data → Transform 1 → Transform 2 → Transform 3 → Output
```

**Mental model:** Think of Pig like Unix pipes on steroids:
```bash
# Unix pipes (local)
cat logs.txt | grep "ERROR" | sort | uniq -c

# Pig (distributed across cluster)
logs = LOAD 'logs.txt';
errors = FILTER logs BY line MATCHES '.*ERROR.*';
sorted = ORDER errors BY line;
unique = DISTINCT sorted;
```

---

### Pig vs Hive vs MapReduce

| Aspect | Pig | Hive | MapReduce |
|--------|-----|------|-----------|
| **Language** | Pig Latin (procedural) | SQL (declarative) | Java (imperative) |
| **Best for** | ETL, data flow pipelines | SQL-style analytics | Custom algorithms |
| **Learning curve** | Medium | Easy (if you know SQL) | Steep |
| **Code length** | 10-20 lines | 5-10 lines | 200+ lines |
| **Flexibility** | High | Medium | Highest |
| **Schema** | Optional (schema-on-read) | Required (tables) | Not applicable |
| **Custom logic** | Easy (UDFs) | Moderate (UDFs) | Native |
| **Use case** | Complex ETL, custom parsing | Standard analytics | ML algorithms |

**When to use Pig:**
- Data cleansing and transformation (ETL)
- Multi-step data pipelines
- Non-standard data formats (logs, JSON with nested fields)
- Prototyping MapReduce jobs quickly
- Joining datasets with complex logic

**When NOT to use Pig:**
- Simple SQL-style queries → Use Hive
- Need real-time queries → Use HBase
- Custom complex algorithms → Use MapReduce
- Small datasets → Use local tools (Python, pandas)

---

### Pig Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  YOU (Data Analyst)                                         │
│  Writes: word_count.pig                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  PIG COMPILER                                               │
│  1. Parser:   Checks Pig Latin syntax                       │
│  2. Optimizer: Rewrites for efficiency (e.g., push filters) │
│  3. Compiler: Generates MapReduce jobs                      │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  MAPREDUCE JOBS (on YARN)                                   │
│  Job 1: Load and filter data                                │
│  Job 2: Group by key                                        │
│  Job 3: Sort results                                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  HDFS                                                       │
│  /output/results/part-r-00000                               │
└─────────────────────────────────────────────────────────────┘

Example: A 10-line Pig script might compile to 3 MapReduce jobs
```

---

### Pig Data Model (The Building Blocks)

Pig works with 4 data types:

```
1. ATOM (Scalar value)
   Examples: "hello", 123, 3.14, true

2. TUPLE (Ordered collection, like a row)
   Example: (1, "Alice", 90000.0)
            └─ field 0   └─ field 1   └─ field 2

3. BAG (Collection of tuples, like a table)
   Example: {
     (1, "Alice", 90000.0),
     (2, "Bob",   75000.0),
     (3, "Carol", 85000.0)
   }

4. MAP (Key-value pairs)
   Example: [name#Alice, age#28, city#NYC]
```

**Data flow example:**
```pig
-- Input: Shakespeare text file
-- Each line becomes a TUPLE with one field

LOAD → BAG of TUPLES
{
  ("To be or not to be"),
  ("That is the question"),
  ...
}

TOKENIZE → BAG of TUPLES with individual words
{
  ("To"),
  ("be"),
  ("or"),
  ...
}

GROUP → BAG with nested BAGS
{
  ("be", {("be"), ("be"), ("be")}),  -- 3 occurrences
  ("or", {("or"), ("or")}),          -- 2 occurrences
  ...
}

COUNT → BAG of TUPLES with counts
{
  ("be", 3),
  ("or", 2),
  ...
}
```

---

## Prerequisites

Before starting, ensure:
```bash
# Check that your cluster is running
docker-compose ps

# You should see these services as "Up":
# - namenode
# - datanode1
# - datanode2
# - resourcemanager
# - nodemanager
```

If services aren't running:
```bash
cd /Users/jason/Files/Practice/demo-little-things/hadoop-tutorial
docker-compose up -d
```

**Data setup:**
```bash
# Upload sample data (if not already done)
docker-compose exec namenode bash
hadoop fs -mkdir -p /user/hadoop/input
hadoop fs -put /datasets/wordcount/shakespeare.txt /user/hadoop/input/
exit
```

---

## Hands-On Exercises

### Exercise 1: Launch Interactive Pig Shell (Grunt)

**What we're doing:** Opening Pig's interactive shell to test commands one at a time.

```bash
# Connect to NameNode container
docker-compose exec namenode bash

# Launch Pig interactive shell
pig
```

**Expected output:**
```
2025-11-15 10:00:00,123 [main] INFO  org.apache.pig.Main - Apache Pig version 0.17.0
2025-11-15 10:00:00,456 [main] INFO  org.apache.pig.Main - Logging error messages to: /opt/pig/logs/pig_1731668400123.log
grunt>
```

**What just happened:**
- You're now in the **Grunt shell** (Pig's interactive mode)
- You can type Pig Latin commands one at a time
- Each command is stored in memory until you execute it
- The `grunt>` prompt shows you're ready to type

**To exit later:** Type `quit` or press `Ctrl+D`

---

### Exercise 2: Load and Inspect Data

**Concept:** Loading data from HDFS into Pig's memory (as a relation/bag).

```pig
-- Load Shakespeare text file (each line becomes a tuple)
lines = LOAD '/user/hadoop/input/shakespeare.txt' AS (line:chararray);

-- View the schema (structure)
DESCRIBE lines;

-- Show first 20 lines
DUMP lines;
```

**Expected output for DESCRIBE:**
```
lines: {line: chararray}
```

**Expected output for DUMP (first few lines):**
```
(THE SONNETS)
()
(by William Shakespeare)
()
(                     1)
(  From fairest creatures we desire increase,)
(  That thereby beauty's rose might never die,)
...
(2025-11-15 10:05:00,789 [main] INFO  org.apache.hadoop.mapreduce.Job - Job job_1731668400001_0001 completed successfully)
```

**What just happened:**

```
Step 1: LOAD command
  ├─ Read file from HDFS: /user/hadoop/input/shakespeare.txt
  ├─ Each line becomes a TUPLE: (line_content)
  └─ Store in relation called "lines" (in memory, not executed yet)

Step 2: DESCRIBE
  ├─ Shows schema: lines has one field called "line" of type chararray
  └─ No MapReduce job (just metadata)

Step 3: DUMP
  ├─ TRIGGERS EXECUTION (lazy evaluation until now!)
  ├─ Pig compiles to MapReduce job
  ├─ MapReduce job reads HDFS file
  ├─ Results stream back to your terminal
  └─ You see the actual line content
```

**Important concept - Lazy Evaluation:**
- `LOAD` doesn't actually read the file (just plans it)
- `DESCRIBE` analyzes metadata only
- `DUMP` or `STORE` triggers actual execution
- This allows Pig to optimize the entire pipeline before running

---

### Exercise 3: Word Count (Step-by-Step Data Flow)

**Concept:** Classic MapReduce word count, written in Pig Latin. We'll build it step-by-step to understand data flow.

**Step 1: Load data**
```pig
lines = LOAD '/user/hadoop/input/shakespeare.txt' AS (line:chararray);
```

**Step 2: Split lines into words**
```pig
words = FOREACH lines GENERATE FLATTEN(TOKENIZE(line)) AS word;
DESCRIBE words;
```

**Expected DESCRIBE output:**
```
words: {word: chararray}
```

**What this does:**
```
Input:  {("To be or not to be"), ("That is the question")}

FOREACH lines:       Process each tuple
TOKENIZE(line):      Split line by whitespace → bag of words
                     ("To be or not") → {("To"), ("be"), ("or"), ("not")}

FLATTEN:             Unwrap nested bag (crucial!)
                     {("To"), ("be"), ("or")} → ("To"), ("be"), ("or")

Output: {("To"), ("be"), ("or"), ("not"), ("to"), ("be"), ("That"), ("is"), ...}
```

**Step 3: Filter out empty words**
```pig
filtered = FILTER words BY word IS NOT NULL AND word != '';
```

**What this does:**
```
Input:  {("To"), (""), ("be"), (""), ("or")}

FILTER: Keep only tuples where word is not null and not empty

Output: {("To"), ("be"), ("or")}
```

**Step 4: Convert to lowercase**
```pig
lowered = FOREACH filtered GENERATE LOWER(word) AS word;
```

**What this does:**
```
Input:  {("To"), ("BE"), ("Or")}

FOREACH: Process each tuple
LOWER:   Convert to lowercase

Output: {("to"), ("be"), ("or")}
```

**Step 5: Group by word**
```pig
grouped = GROUP lowered BY word;
DESCRIBE grouped;
```

**Expected DESCRIBE output:**
```
grouped: {group: chararray, lowered: {(word: chararray)}}
```

**What this does (THE KEY STEP):**
```
Input:  {("be"), ("to"), ("be"), ("or"), ("be"), ("to")}

GROUP BY word: Collect all tuples with same word

Output: {
  ("be", {("be"), ("be"), ("be")}),     -- 3 occurrences
  ("to", {("to"), ("to")}),             -- 2 occurrences
  ("or", {("or")})                      -- 1 occurrence
}

Structure:
  (group,      lowered)
   └─ key      └─ bag of all matching tuples
```

**Try this to see grouped data:**
```pig
sample_grouped = LIMIT grouped 5;
DUMP sample_grouped;
```

**Expected output:**
```
(a,{(a),(a),(a),(a),...})
(abandon,{(abandon),(abandon)})
(abandoned,{(abandoned)})
...
```

**Step 6: Count occurrences**
```pig
counts = FOREACH grouped GENERATE group AS word, COUNT(lowered) AS count;
DESCRIBE counts;
```

**Expected DESCRIBE output:**
```
counts: {word: chararray, count: long}
```

**What this does:**
```
Input:  ("be", {("be"), ("be"), ("be")})

FOREACH: Process each group
group:   The word we grouped by ("be")
COUNT:   Count tuples in the bag (3)

Output: ("be", 3)
```

**Step 7: Sort by count (descending)**
```pig
sorted = ORDER counts BY count DESC;
```

**What this does:**
```
Input:  {("be", 3), ("or", 2), ("to", 5)}

ORDER BY count DESC: Sort by count, highest first

Output: {("to", 5), ("be", 3), ("or", 2)}
```

**Step 8: View top 20 results**
```pig
top_20 = LIMIT sorted 20;
DUMP top_20;
```

**Expected output:**
```
(the,1090)
(and,967)
(to,863)
(of,670)
(i,631)
(a,548)
(my,513)
(in,451)
(you,433)
(is,412)
...
```

**Step 9: Save results to HDFS**
```pig
STORE sorted INTO '/user/hadoop/output/pig_wordcount';
```

**Expected output:**
```
2025-11-15 10:15:00,123 [main] INFO  org.apache.pig.backend.hadoop.executionengine.mapReduceLayer.MapReduceLauncher - Success!
```

**Verify results:**
```bash
# Exit Pig shell
quit

# View output files
hadoop fs -ls /user/hadoop/output/pig_wordcount/
```

**Expected output:**
```
Found 2 items
-rw-r--r--   2 hadoop supergroup          0 2025-11-15 10:15 /user/hadoop/output/pig_wordcount/_SUCCESS
-rw-r--r--   2 hadoop supergroup      85264 2025-11-15 10:15 /user/hadoop/output/pig_wordcount/part-r-00000
```

**View actual results:**
```bash
hadoop fs -cat /user/hadoop/output/pig_wordcount/part-r-00000 | head -20
```

---

### Exercise 4: Complete Word Count Script (Batch Mode)

**Concept:** Running Pig scripts from files instead of interactive mode.

**Create script file:**
```bash
# Inside namenode container
cat > /tmp/word_count.pig << 'EOF'
-- =====================================================
-- Word Count in Pig Latin
-- =====================================================

-- Load text file
lines = LOAD '/user/hadoop/input/shakespeare.txt' AS (line:chararray);

-- Split into words and flatten
words = FOREACH lines GENERATE FLATTEN(TOKENIZE(line)) AS word;

-- Remove empty words
filtered = FILTER words BY word IS NOT NULL AND word != '';

-- Normalize to lowercase
normalized = FOREACH filtered GENERATE LOWER(word) AS word;

-- Group by word
grouped = GROUP normalized BY word;

-- Count occurrences
counts = FOREACH grouped GENERATE
  group AS word,
  COUNT(normalized) AS count;

-- Sort by frequency (descending)
sorted = ORDER counts BY count DESC;

-- Save results
STORE sorted INTO '/user/hadoop/output/pig_wordcount_batch';
EOF
```

**Run the script:**
```bash
pig /tmp/word_count.pig
```

**Expected output:**
```
2025-11-15 10:20:00,123 [main] INFO  org.apache.pig.Main - Apache Pig version 0.17.0
2025-11-15 10:20:01,456 [main] INFO  org.apache.pig.tools.grunt.Grunt - Connecting to hadoop file system at: hdfs://namenode:9000
...
2025-11-15 10:20:45,789 [main] INFO  org.apache.hadoop.mapreduce.Job - Job job_1731668400002_0001 completed successfully
...
2025-11-15 10:20:46,012 [main] INFO  org.apache.pig.Main - Pig script completed in 46 seconds
```

**What happened:**
1. Pig parsed the entire script file
2. Optimized the pipeline (e.g., pushed filter before group)
3. Compiled to MapReduce jobs (likely 2-3 jobs)
4. Submitted jobs to YARN
5. Jobs ran across the cluster
6. Results written to HDFS

**Verify results:**
```bash
hadoop fs -cat /user/hadoop/output/pig_wordcount_batch/part-r-00000 | head -10
```

---

### Exercise 5: Working with Structured Data (CSV)

**Concept:** Loading and transforming CSV files (like employee data).

**First, let's create sample CSV data:**
```bash
# Create sample employees.csv
cat > /tmp/employees.csv << 'EOF'
1,Alice Smith,Engineering,95000,28,2020-01-15
2,Bob Johnson,Marketing,75000,35,2019-06-20
3,Carol Williams,Engineering,85000,31,2021-03-10
4,David Brown,Sales,70000,29,2020-08-05
5,Eve Davis,Engineering,105000,42,2018-02-14
6,Frank Miller,Marketing,68000,26,2022-01-20
7,Grace Wilson,Sales,72000,33,2019-11-30
8,Henry Moore,Engineering,92000,37,2020-05-18
9,Ivy Taylor,Marketing,78000,30,2021-07-22
10,Jack Anderson,Sales,88000,45,2017-09-08
EOF

# Upload to HDFS
hadoop fs -mkdir -p /user/hadoop/input
hadoop fs -put -f /tmp/employees.csv /user/hadoop/input/
```

**Now launch Pig and work with the data:**
```pig
-- Load CSV with schema
employees = LOAD '/user/hadoop/input/employees.csv'
  USING PigStorage(',') AS (
    employee_id:int,
    name:chararray,
    department:chararray,
    salary:double,
    age:int,
    hire_date:chararray
  );

-- View schema
DESCRIBE employees;
```

**Expected DESCRIBE output:**
```
employees: {employee_id: int, name: chararray, department: chararray, salary: double, age: int, hire_date: chararray}
```

**Filter high earners:**
```pig
high_earners = FILTER employees BY salary > 90000;
DUMP high_earners;
```

**Expected output:**
```
(1,Alice Smith,Engineering,95000.0,28,2020-01-15)
(5,Eve Davis,Engineering,105000.0,42,2018-02-14)
(8,Henry Moore,Engineering,92000.0,37,2020-05-18)
```

**Calculate bonuses:**
```pig
with_bonus = FOREACH employees GENERATE
  name,
  salary,
  (salary * 0.15) AS bonus:double,
  (salary + (salary * 0.15)) AS total_comp:double;

DUMP with_bonus;
```

**Expected output:**
```
(Alice Smith,95000.0,14250.0,109250.0)
(Bob Johnson,75000.0,11250.0,86250.0)
(Carol Williams,85000.0,12750.0,97750.0)
...
```

**Group by department and aggregate:**
```pig
by_dept = GROUP employees BY department;

dept_stats = FOREACH by_dept GENERATE
  group AS department,
  COUNT(employees) AS employee_count,
  AVG(employees.salary) AS avg_salary,
  MAX(employees.salary) AS max_salary,
  MIN(employees.salary) AS min_salary;

DUMP dept_stats;
```

**Expected output:**
```
(Engineering,4,94250.0,105000.0,85000.0)
(Marketing,3,73666.67,78000.0,68000.0)
(Sales,3,76666.67,88000.0,70000.0)
```

**What just happened:**
```
Input: {
  (1, Alice, Engineering, 95000, ...),
  (2, Bob, Marketing, 75000, ...),
  (3, Carol, Engineering, 85000, ...),
  ...
}

GROUP BY department:
{
  (Engineering, {(1, Alice, Engineering, 95000), (3, Carol, Engineering, 85000), ...}),
  (Marketing, {(2, Bob, Marketing, 75000), ...}),
  (Sales, {...})
}

FOREACH with aggregations:
{
  (Engineering, 4, 94250.0, 105000.0, 85000.0),
  (Marketing, 3, 73666.67, 78000.0, 68000.0),
  (Sales, 3, 76666.67, 88000.0, 70000.0)
}
```

---

### Exercise 6: Advanced Transformations (FLATTEN vs No FLATTEN)

**Concept:** Understanding FLATTEN - the most confusing but powerful Pig operation.

**Without FLATTEN (creates nested bags):**
```pig
lines = LOAD '/user/hadoop/input/shakespeare.txt' AS (line:chararray);

-- TOKENIZE returns a bag for each line
words_nested = FOREACH lines GENERATE TOKENIZE(line) AS words;

DESCRIBE words_nested;
sample = LIMIT words_nested 3;
DUMP sample;
```

**Expected DESCRIBE:**
```
words_nested: {words: {(word: chararray)}}
             └─ BAG containing BAG of tuples
```

**Expected DUMP:**
```
({(THE),(SONNETS)})
({})
({(by),(William),(Shakespeare)})
```

**With FLATTEN (unwraps nested bags):**
```pig
words_flat = FOREACH lines GENERATE FLATTEN(TOKENIZE(line)) AS word;

DESCRIBE words_flat;
sample_flat = LIMIT words_flat 10;
DUMP sample_flat;
```

**Expected DESCRIBE:**
```
words_flat: {word: chararray}
           └─ Simple tuple (no nested bag)
```

**Expected DUMP:**
```
(THE)
(SONNETS)
(by)
(William)
(Shakespeare)
(From)
(fairest)
(creatures)
...
```

**Visual comparison:**
```
Line: "To be or not to be"

WITHOUT FLATTEN:
  1 tuple → ({(To),(be),(or),(not),(to),(be)})

WITH FLATTEN:
  6 tuples → (To)
             (be)
             (or)
             (not)
             (to)
             (be)
```

**Why FLATTEN matters:**
- **Without FLATTEN:** You get 1 row per input line (nested structure)
- **With FLATTEN:** You get 1 row per word (flat structure)
- **For word count:** We need flat structure to GROUP BY individual words!

---

### Exercise 7: JOIN Operations

**Concept:** Combining two datasets (like SQL JOIN).

**Create a second dataset (departments):**
```bash
cat > /tmp/departments.csv << 'EOF'
Engineering,New York,ENG
Marketing,San Francisco,MKT
Sales,Chicago,SLS
HR,Boston,HR
EOF

hadoop fs -put -f /tmp/departments.csv /user/hadoop/input/
```

**Join employees with departments:**
```pig
-- Load both datasets
employees = LOAD '/user/hadoop/input/employees.csv'
  USING PigStorage(',') AS (
    emp_id:int, name:chararray, dept:chararray,
    salary:double, age:int, hire_date:chararray
  );

departments = LOAD '/user/hadoop/input/departments.csv'
  USING PigStorage(',') AS (
    dept_name:chararray, location:chararray, code:chararray
  );

-- Inner join
joined = JOIN employees BY dept, departments BY dept_name;

-- Select relevant columns
result = FOREACH joined GENERATE
  employees::name AS employee_name,
  employees::dept AS department,
  employees::salary AS salary,
  departments::location AS office_location;

DUMP result;
```

**Expected output:**
```
(Alice Smith,Engineering,95000.0,New York)
(Carol Williams,Engineering,85000.0,New York)
(Eve Davis,Engineering,105000.0,New York)
(Henry Moore,Engineering,92000.0,New York)
(Bob Johnson,Marketing,75000.0,San Francisco)
(Frank Miller,Marketing,68000.0,San Francisco)
(Ivy Taylor,Marketing,78000.0,San Francisco)
(David Brown,Sales,70000.0,Chicago)
(Grace Wilson,Sales,72000.0,Chicago)
(Jack Anderson,Sales,88000.0,Chicago)
```

**What happened:**
```
employees:              departments:
(Alice, Engineering)    (Engineering, New York)
(Bob, Marketing)        (Marketing, San Francisco)
(Carol, Engineering)    (Sales, Chicago)

JOIN ON dept = dept_name:
(Alice, Engineering, 95000, New York)
(Bob, Marketing, 75000, San Francisco)
(Carol, Engineering, 85000, New York)
```

---

### Exercise 8: Using DISTINCT

**Concept:** Removing duplicate values.

```pig
employees = LOAD '/user/hadoop/input/employees.csv'
  USING PigStorage(',') AS (
    emp_id:int, name:chararray, dept:chararray,
    salary:double, age:int, hire_date:chararray
  );

-- Extract just departments (will have duplicates)
depts_all = FOREACH employees GENERATE dept;
DUMP depts_all;
```

**Expected output (with duplicates):**
```
(Engineering)
(Marketing)
(Engineering)
(Sales)
(Engineering)
(Marketing)
(Sales)
(Engineering)
(Marketing)
(Sales)
```

**Remove duplicates:**
```pig
depts_unique = DISTINCT depts_all;
DUMP depts_unique;
```

**Expected output (no duplicates):**
```
(Engineering)
(Marketing)
(Sales)
```

**What happened:**
- `DISTINCT` compiles to a MapReduce job
- Mappers emit each value with a dummy key
- Reducers deduplicate based on the key
- Similar to `GROUP BY` but keeps only unique keys

---

### Exercise 9: String Functions

**Concept:** Pig has rich built-in functions for string manipulation.

```pig
employees = LOAD '/user/hadoop/input/employees.csv'
  USING PigStorage(',') AS (
    emp_id:int, name:chararray, dept:chararray,
    salary:double, age:int, hire_date:chararray
  );

-- String transformations
string_ops = FOREACH employees GENERATE
  name,
  UPPER(name) AS name_upper,
  LOWER(name) AS name_lower,
  SUBSTRING(name, 0, 5) AS name_prefix,
  SIZE(name) AS name_length,
  CONCAT(name, ' - ', dept) AS full_info;

DUMP string_ops;
```

**Expected output:**
```
(Alice Smith,ALICE SMITH,alice smith,Alice,11,Alice Smith - Engineering)
(Bob Johnson,BOB JOHNSON,bob johnson,Bob J,11,Bob Johnson - Marketing)
(Carol Williams,CAROL WILLIAMS,carol williams,Carol,15,Carol Williams - Engineering)
...
```

**Common string functions:**
```pig
-- Extract initials
initials = FOREACH employees GENERATE
  REGEX_EXTRACT(name, '(\\w)\\w* (\\w)\\w*', 1) AS first_initial,
  REGEX_EXTRACT(name, '(\\w)\\w* (\\w)\\w*', 2) AS last_initial;

-- Output: (A, S), (B, J), (C, W), ...
```

---

### Exercise 10: Debugging with EXPLAIN and ILLUSTRATE

**Concept:** Understanding how Pig compiles your script.

**EXPLAIN shows the execution plan:**
```pig
employees = LOAD '/user/hadoop/input/employees.csv'
  USING PigStorage(',') AS (emp_id:int, name:chararray, dept:chararray, salary:double, age:int, hire_date:chararray);

high_earners = FILTER employees BY salary > 90000;
sorted = ORDER high_earners BY salary DESC;

EXPLAIN sorted;
```

**Expected output (abbreviated):**
```
--------------------------------------------------------------
| Logical Plan:
| employees: Load(/user/hadoop/input/employees.csv)
| high_earners: Filter[salary > 90000]
| sorted: Order[salary DESC]
--------------------------------------------------------------
| Physical Plan:
| MapReduce Job 1:
|   Map: Load + Filter
|   Reduce: (empty)
| MapReduce Job 2:
|   Map: Sample for sorting
|   Reduce: Sort
--------------------------------------------------------------
```

**What this tells you:**
- Pig will create **2 MapReduce jobs**
- Job 1: Load data and apply filter (in mapper)
- Job 2: Sort data (requires reducer)

**ILLUSTRATE shows sample data flow:**
```pig
ILLUSTRATE sorted;
```

**Expected output:**
```
--------------------------------------------------------------
| employees     | (5, Eve Davis, Engineering, 105000.0, 42, 2018-02-14)
|               | (1, Alice Smith, Engineering, 95000.0, 28, 2020-01-15)
--------------------------------------------------------------
| high_earners  | (5, Eve Davis, Engineering, 105000.0, 42, 2018-02-14)
|               | (1, Alice Smith, Engineering, 95000.0, 28, 2020-01-15)
--------------------------------------------------------------
| sorted        | (5, Eve Davis, Engineering, 105000.0, 42, 2018-02-14)
|               | (1, Alice Smith, Engineering, 95000.0, 28, 2020-01-15)
--------------------------------------------------------------
```

**Why this is useful:**
- Shows how data transforms through each step
- Uses synthetic sample data (not full dataset)
- Great for debugging without running expensive jobs

---

## Real-World Applications

### Example 1: Web Log Analysis (ETL Pipeline)

**Scenario:** Process Apache access logs to find top pages and error rates.

```pig
-- Load raw logs (messy format)
raw_logs = LOAD '/logs/access_logs.txt' USING TextLoader() AS (line:chararray);

-- Parse log lines (custom regex)
parsed = FOREACH raw_logs GENERATE
  REGEX_EXTRACT(line, '^(\\S+)', 1) AS ip,
  REGEX_EXTRACT(line, '^\\S+ \\S+ \\S+ \\[([^\\]]+)\\]', 1) AS timestamp,
  REGEX_EXTRACT(line, '"\\w+ ([^"]+) HTTP', 1) AS path,
  (int)REGEX_EXTRACT(line, '" (\\d{3}) ', 1) AS status_code,
  (int)REGEX_EXTRACT(line, '" \\d+ (\\d+)', 1) AS bytes;

-- Filter valid requests
valid = FILTER parsed BY ip IS NOT NULL;

-- Find top pages
by_path = GROUP valid BY path;
page_stats = FOREACH by_path GENERATE
  group AS page,
  COUNT(valid) AS hits,
  SUM(valid.bytes) AS total_bytes;

top_pages = ORDER page_stats BY hits DESC;
top_10 = LIMIT top_pages 10;

-- Find error rate by hour
errors = FILTER valid BY status_code >= 400;
by_hour = GROUP valid BY SUBSTRING(timestamp, 0, 13);  -- Group by hour

error_rate = FOREACH by_hour GENERATE
  group AS hour,
  COUNT(valid) AS total_requests,
  (double)SUM(valid.status_code >= 400 ? 1 : 0) AS error_count;

-- Store results
STORE top_10 INTO '/output/top_pages';
STORE error_rate INTO '/output/error_rates';
```

**Use case:** This is what Yahoo/LinkedIn run to analyze billions of log entries daily.

---

### Example 2: Sessionization (User Session Analysis)

**Scenario:** Group user clicks into sessions (30-minute timeout).

```pig
-- Load clickstream
clicks = LOAD '/data/clickstream.csv' USING PigStorage(',') AS
  (user_id:chararray, timestamp:long, page:chararray, action:chararray);

-- Sort by user and time
sorted = ORDER clicks BY user_id, timestamp;

-- Group by user
by_user = GROUP sorted BY user_id;

-- Custom UDF to identify sessions (Python/Java UDF)
-- (Simplified version here)
sessions = FOREACH by_user {
  -- Calculate time differences
  -- If gap > 30 min, new session
  GENERATE group AS user_id, COUNT(sorted) AS total_clicks;
}

STORE sessions INTO '/output/user_sessions';
```

**Real-world use:** E-commerce sites track shopping sessions this way.

---

### Example 3: Data Quality Checks

**Scenario:** Find invalid records before processing.

```pig
data = LOAD '/data/raw/transactions.csv' USING PigStorage(',') AS
  (transaction_id:chararray, amount:double, date:chararray, user_id:chararray);

-- Find invalid records
invalid_amount = FILTER data BY amount IS NULL OR amount < 0;
invalid_date = FILTER data BY date IS NULL OR SIZE(date) != 10;
invalid_user = FILTER data BY user_id IS NULL OR SIZE(user_id) == 0;

-- Union all invalid records
all_invalid = UNION invalid_amount, invalid_date, invalid_user;

-- Get distinct invalid records
invalid_distinct = DISTINCT all_invalid;

-- Count by issue type (would need custom logic)
STORE invalid_distinct INTO '/output/data_quality_issues';

-- Process only valid data
valid = FILTER data BY
  amount IS NOT NULL AND amount >= 0 AND
  date IS NOT NULL AND SIZE(date) == 10 AND
  user_id IS NOT NULL AND SIZE(user_id) > 0;

STORE valid INTO '/output/clean_data';
```

---

## Common Patterns and Best Practices

### Pattern 1: Early Filtering (Push Down Filters)

**❌ Bad (filter late):**
```pig
data = LOAD 'huge_dataset.txt';
processed = FOREACH data GENERATE complex_transformation(field);
grouped = GROUP processed BY key;
filtered = FILTER grouped BY condition;  -- Too late!
```

**✅ Good (filter early):**
```pig
data = LOAD 'huge_dataset.txt';
filtered = FILTER data BY condition;  -- Filter first!
processed = FOREACH filtered GENERATE complex_transformation(field);
grouped = GROUP processed BY key;
```

**Why:** Reduces data volume early → faster processing.

---

### Pattern 2: Using Schemas

**❌ Bad (no schema):**
```pig
data = LOAD 'file.csv' USING PigStorage(',');
result = FOREACH data GENERATE $0, $1, $2;  -- What are these?
```

**✅ Good (explicit schema):**
```pig
data = LOAD 'file.csv' USING PigStorage(',') AS
  (user_id:int, name:chararray, salary:double);
result = FOREACH data GENERATE user_id, name, salary;  -- Clear!
```

**Why:** Easier to read, better type checking, Pig can optimize better.

---

### Pattern 3: Avoid Unnecessary DISTINCT

**❌ Bad:**
```pig
grouped = GROUP data BY key;
distinct_keys = DISTINCT (FOREACH grouped GENERATE group);
```

**✅ Good:**
```pig
grouped = GROUP data BY key;
keys = FOREACH grouped GENERATE group;  -- Already unique!
```

**Why:** `GROUP` already produces unique keys, no need for `DISTINCT`.

---

## Key Takeaways

✅ **Pig Latin is a data flow language** - you describe transformations step-by-step

✅ **Lazy evaluation** - commands don't run until DUMP or STORE

✅ **FLATTEN is crucial** - unwraps nested bags to create flat structures

✅ **Pig sits between SQL and MapReduce** - easier than Java, more flexible than SQL

✅ **Great for ETL and data pipelines** - cleaning, parsing, joining complex datasets

✅ **Compiles to MapReduce** - one Pig script → multiple MapReduce jobs

✅ **Use EXPLAIN and ILLUSTRATE** - debug before running expensive jobs

---

## Common Issues and Solutions

### Issue 1: "ERROR: Scalar has more than one row in the output"

**Error message:**
```
ERROR 1025: Invalid field projection. Projected field [salary] does not exist in schema
```

**What's wrong:** Trying to access a field that doesn't exist (typo or wrong schema).

**Solution:**
```pig
-- Use DESCRIBE to check schema
DESCRIBE employees;

-- Fix field name
correct = FOREACH employees GENERATE name, salary;  -- Not 'salry'
```

---

### Issue 2: "java.lang.OutOfMemoryError"

**What's wrong:** Processing too much data in memory (e.g., COGROUP large datasets).

**Solution:**
```pig
-- Use parallel execution
SET default_parallel 10;  -- Use 10 reducers

-- Or increase memory
SET mapred.map.child.java.opts '-Xmx2048m';
```

---

### Issue 3: "ERROR: org.apache.pig.backend.executionengine.ExecException: ERROR 0: Scalar has more than one row"

**What's wrong:** Trying to use a bag as a scalar (single value).

**Example problem:**
```pig
grouped = GROUP data BY key;
bad = FOREACH grouped GENERATE data.field;  -- Returns bag, not scalar!
```

**Solution:**
```pig
-- Use aggregate function
good = FOREACH grouped GENERATE MAX(data.field);  -- Returns scalar
```

---

## Quick Reference Card

```pig
# ====================
# LOAD/STORE
# ====================
data = LOAD 'file.txt' AS (field:chararray);
data = LOAD 'file.csv' USING PigStorage(',') AS (id:int, name:chararray);
STORE data INTO '/output/results';

# ====================
# TRANSFORMATIONS
# ====================
filtered = FILTER data BY age > 30;
projected = FOREACH data GENERATE name, age, (age + 1) AS next_age;
grouped = GROUP data BY department;
distinct_vals = DISTINCT data;
sorted = ORDER data BY salary DESC;
limited = LIMIT data 10;

# ====================
# AGGREGATIONS
# ====================
stats = FOREACH grouped GENERATE
  group AS dept,
  COUNT(data) AS count,
  AVG(data.salary) AS avg_salary,
  MAX(data.salary) AS max_salary,
  MIN(data.salary) AS min_salary,
  SUM(data.salary) AS total_salary;

# ====================
# JOINS
# ====================
joined = JOIN table1 BY key, table2 BY key;
left_join = JOIN table1 BY key LEFT OUTER, table2 BY key;

# ====================
# STRING FUNCTIONS
# ====================
UPPER(str), LOWER(str), SUBSTRING(str, start, end)
SIZE(str), CONCAT(str1, str2)
TOKENIZE(line)  -- Split by whitespace
REGEX_EXTRACT(str, pattern, index)

# ====================
# MATH FUNCTIONS
# ====================
ABS(x), CEIL(x), FLOOR(x), ROUND(x)
SQRT(x), LOG(x), EXP(x)

# ====================
# FLATTEN
# ====================
words = FOREACH lines GENERATE FLATTEN(TOKENIZE(line));

# ====================
# DEBUGGING
# ====================
DESCRIBE data;           -- Show schema
DUMP data;               -- Show data (triggers execution)
EXPLAIN query;           -- Show execution plan
ILLUSTRATE query;        -- Show sample data flow

# ====================
# SETTINGS
# ====================
SET default_parallel 10;                           -- Number of reducers
SET mapred.map.tasks.speculative.execution false;  -- Disable speculative execution
```

---

## Next Steps

**You've mastered Pig basics!** Now you can:

1. **Move to Tutorial 06** to learn Sqoop (importing data from databases)
2. **Experiment more:**
   ```bash
   # Try analyzing the log files
   hadoop fs -put /datasets/logs/access_logs.txt /user/hadoop/input/

   # Write a Pig script to find:
   # - Top 10 IP addresses by request count
   # - Most common HTTP status codes
   # - Total bytes transferred by hour
   ```
3. **Learn more:**
   - Official Pig documentation: https://pig.apache.org/docs/latest/
   - Write custom UDFs (User Defined Functions) in Python/Java

---

**Exit container:** Type `exit` and press Enter
