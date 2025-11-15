# Tutorial 05: Pig Scripts

Learn data transformation using Apache Pig Latin.

## Learning Objectives

- Understand Pig Latin syntax
- Load data from HDFS
- Transform data with Pig operators
- Group and aggregate data
- Filter and join datasets
- Write Pig scripts

## Prerequisites

- HDFS running with sample data
- Pig installation
- Sample text files uploaded to HDFS

## Pig Data Model

### Atoms
- Simple atomic value (e.g., "hello", 123, 3.14)

### Tuples
- Ordered collection of fields: (1, "hello", 3.14)

### Bags
- Collection of tuples: {(1, 2), (3, 4)}

### Maps
- Key-value pairs: [name#John, age#30]

## Basic Pig Operations

### Load Data

```pig
-- Load text file
data = LOAD '/input/shakespeare.txt' AS (line:chararray);

-- Load CSV file
employees = LOAD '/user/hive/warehouse/data/employees.csv'
  USING PigStorage(',') AS
  (employee_id:int, name:chararray, department:chararray,
   salary:double, age:int, hire_date:chararray);
```

### Transformations

```pig
-- FILTER: Keep rows matching condition
high_salary = FILTER employees BY salary > 90000;

-- FOREACH: Project and transform columns
salary_info = FOREACH employees GENERATE name, salary, (salary * 0.15) as bonus;

-- DISTINCT: Remove duplicates
unique_departments = FOREACH employees GENERATE department;
unique_depts = DISTINCT unique_departments;

-- MAP/REDUCE style transformations
reduced = FOREACH employees GENERATE department, salary;
```

### Word Count Example

```pig
-- Load text file
text = LOAD '/input/shakespeare.txt' AS (line:chararray);

-- Split into words
words = FOREACH text GENERATE FLATTEN(TOKENIZE(line)) as word;

-- Filter out empty words
filtered_words = FILTER words BY word != '';

-- Convert to lowercase
lower_words = FOREACH filtered_words GENERATE LOWER(word) as word;

-- Group by word
grouped = GROUP lower_words BY word;

-- Count occurrences
word_counts = FOREACH grouped GENERATE group as word, COUNT(lower_words) as count;

-- Sort by count descending
sorted = ORDER word_counts BY count DESC;

-- Save results
STORE sorted INTO '/output/word_count_pig';
```

### Running Pig Scripts

#### Interactive Mode (Grunt Shell)

```bash
docker-compose exec namenode pig

# Then type Pig commands
grunt> data = LOAD '/input/shakespeare.txt' AS (line:chararray);
grunt> DESCRIBE data;
grunt> DUMP data;
```

#### Batch Mode (Script File)

Create `word_count.pig`:
```pig
text = LOAD '/input/shakespeare.txt' AS (line:chararray);
words = FOREACH text GENERATE FLATTEN(TOKENIZE(line)) as word;
words = FILTER words BY word != '';
words = FOREACH words GENERATE LOWER(word) as word;
grouped = GROUP words BY word;
counts = FOREACH grouped GENERATE group as word, COUNT(words) as count;
counts = ORDER counts BY count DESC;
STORE counts INTO '/pig_output/word_counts';
```

Run it:
```bash
docker-compose exec namenode pig word_count.pig
```

## Advanced Operations

### JOIN

```pig
-- Inner join
result = JOIN employees BY employee_id, customers BY customer_id;

-- Left outer join
result = JOIN employees BY employee_id LEFT OUTER,
              customers BY customer_id;
```

### GROUP BY

```pig
-- Group and aggregate
by_dept = GROUP employees BY department;
dept_stats = FOREACH by_dept GENERATE
  group as department,
  COUNT(employees) as count,
  AVG(employees.salary) as avg_salary,
  MAX(employees.salary) as max_salary;
```

### ORDER BY

```pig
-- Sort data
sorted_employees = ORDER employees BY salary DESC;
```

### LIMIT

```pig
-- Take first N rows
top_10 = LIMIT sorted_employees 10;
```

### UNION

```pig
-- Combine datasets
all_data = UNION dataset1, dataset2;
```

### String Functions

```pig
-- Extract substring
initials = FOREACH employees GENERATE
  SUBSTRING(name, 0, 1) as initial;

-- String concatenation
full_info = FOREACH employees GENERATE
  CONCAT(name, ':', department) as info;

-- String length
name_lengths = FOREACH employees GENERATE
  name, SIZE(name) as name_length;
```

### Math Functions

```pig
-- Arithmetic
computed = FOREACH employees GENERATE
  name,
  salary,
  (salary * 1.1) as salary_increase,
  ROUND(salary * 0.15) as bonus;
```

## Complete Example: Log Analysis

Create `log_analysis.pig`:

```pig
-- Load access logs
logs = LOAD '/logs/access_logs.txt'
  USING PigStorage(' ') AS
  (ip:chararray, dash1:chararray, dash2:chararray,
   timestamp:chararray, timezone:chararray, request:chararray,
   status_code:int, size:int, referer:chararray, user_agent:chararray);

-- Extract HTTP method and path from request
requests = FOREACH logs GENERATE
  ip,
  status_code,
  FLATTEN(TOKENIZE(request)) as request_part;

-- Group by status code
by_status = GROUP logs BY status_code;

-- Count by status
status_counts = FOREACH by_status GENERATE
  group as status,
  COUNT(logs) as count;

-- Sort
sorted_status = ORDER status_counts BY count DESC;

-- Store results
STORE sorted_status INTO '/output/log_analysis';
```

## Running the Examples

```bash
# Upload data to HDFS
docker-compose exec namenode bash
hadoop fs -mkdir -p /logs
hadoop fs -put /datasets/logs/access_logs.txt /logs/

# Run Pig script
docker-compose exec namenode pig /tutorials/05-pig-scripts/log_analysis.pig

# View results
hadoop fs -cat /output/log_analysis/part-m-00000 | head -20
```

## Pig vs MapReduce

| Aspect | Pig | MapReduce |
|--------|-----|-----------|
| Language | Pig Latin (high-level) | Java (low-level) |
| Learning Curve | Easier | Steeper |
| Development Time | Faster | Slower |
| Performance | Generally slower | Faster |
| Flexibility | Lower | Higher |
| Debugging | Easier | Harder |

## Built-in Functions

### Aggregation Functions
- COUNT, SUM, AVG, MIN, MAX
- CONCAT_BAGS

### String Functions
- LOWER, UPPER, SUBSTRING, SIZE, CONCAT
- SPLIT, TOKENIZE

### Math Functions
- ABS, CEIL, FLOOR, ROUND, SQRT
- EXP, LOG

### Date Functions
- TODAY, NOW, ToDate, ToString

## Exercises

1. Write a Pig script to count word frequencies in Shakespeare text
2. Load employee CSV and calculate average salary by department
3. Filter employees earning more than $90,000 and group by department
4. Analyze access logs and find top 10 IP addresses
5. Join employee and salary data to find high earners

## Debugging

```pig
-- Use DUMP to see intermediate results
DUMP employees;
DUMP filtered_data;

-- Use DESCRIBE to see schema
DESCRIBE employees;

-- Explain query execution plan
EXPLAIN word_counts;
```

## Performance Tips

1. Use FILTER early to reduce data size
2. Apply LIMIT before expensive operations
3. Use appropriate data types
4. Consider using schemas for better optimization
