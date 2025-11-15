# Hadoop Commands Cheatsheet

Quick reference for common Hadoop ecosystem commands.

## Docker Compose Commands

### Starting and Stopping

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View status
docker-compose ps

# View logs
docker-compose logs -f [SERVICE_NAME]

# Execute command in container
docker-compose exec [SERVICE_NAME] [COMMAND]
```

## HDFS Commands

### Connect to HDFS

```bash
# Connect to NameNode shell
docker-compose exec namenode bash

# Set Java home
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$PATH
```

### File Operations

```bash
# List files
hadoop fs -ls /path
hadoop fs -ls -h /path          # Human readable
hadoop fs -ls -R /path          # Recursive

# Create directory
hadoop fs -mkdir /path
hadoop fs -mkdir -p /path/subdir

# Upload file
hadoop fs -put local_file /hdfs/path
hadoop fs -putmerge local_dir /hdfs/path

# Download file
hadoop fs -get /hdfs/path local_file
hadoop fs -getmerge /hdfs/dir local_file

# Copy within HDFS
hadoop fs -cp /source /destination

# Move within HDFS
hadoop fs -mv /source /destination

# Delete file
hadoop fs -rm /path/file
hadoop fs -rm -r /path/directory
hadoop fs -rmdir /empty/directory

# View file content
hadoop fs -cat /path/file
hadoop fs -cat /path/file | head -n 20
hadoop fs -cat /path/file | tail -n 10
```

### File Information

```bash
# Check file size
hadoop fs -du -h /path
hadoop fs -du -s /path

# Disk usage
hadoop fs -df -h

# File status
hadoop fs -stat "%s %b %o %n %r %y" /path/file

# Count objects
hadoop fs -count /path

# Find files
hadoop fs -find /path -name "pattern"
```

### Permissions

```bash
# Change permissions
hadoop fs -chmod 755 /path
hadoop fs -chmod -R 777 /directory

# Change owner
hadoop fs -chown user:group /path
hadoop fs -chown -R user:group /directory
```

### Text Operations

```bash
# Display file
hadoop fs -text /path/file

# View compressed file
hadoop fs -text /path/file.gz

# Compare files
hadoop fs -getmerge /source1 /source2 merged_file
```

## YARN Commands

### Connect to YARN

```bash
# Connect to ResourceManager
docker-compose exec resourcemanager bash
```

### Job Management

```bash
# List running applications
yarn application -list

# List all applications
yarn application -list -appStates ALL

# Get application status
yarn application -status application_id

# Kill application
yarn application -kill application_id

# Get application logs
yarn logs -applicationId application_id
yarn logs -applicationId application_id -appOwner user

# View job tracking
mapred job -list
mapred job -status job_id
```

### Queue Management

```bash
# List queues
yarn queue -list

# Queue status
yarn queue -status queue_name

# Submit to specific queue
yarn jar ... -Dmapreduce.job.queuename=queue_name
```

### Resource Management

```bash
# Get cluster info
yarn node -list
yarn node -list -all
yarn node -status node_id

# RM Web UI
# Open http://localhost:8088
```

## MapReduce Commands

### Running Jobs

```bash
# Run example word count
yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount /input /output

# With custom parameters
yarn jar myjar.jar MyClass \
  -Dmapreduce.job.reduces=2 \
  -Dmapreduce.map.memory.mb=1024 \
  /input /output

# With map and reduce functions
yarn jar myjar.jar MyMapReduce \
  -Dmapreduce.job.reduces=4 \
  -Dmapreduce.map.java.opts="-Xmx512m" \
  -Dmapreduce.reduce.java.opts="-Xmx512m" \
  /input /output
```

### Job History

```bash
# View history
mapred job -history output_path

# Get job counters
mapred job -counter job_id counter_name
```

## Hive Commands

### Connect to Hive

```bash
# HiveServer2 shell
docker-compose exec hive-server hive

# Beeline (JDBC client)
beeline -u "jdbc:hive2://localhost:10000" -n hadoop
beeline> SHOW TABLES;
beeline> EXIT;
```

### Database Operations

```sql
-- Show databases
SHOW DATABASES;
USE database_name;

-- Create database
CREATE DATABASE IF NOT EXISTS my_db;

-- Drop database
DROP DATABASE IF EXISTS my_db;
```

### Table Operations

```sql
-- List tables
SHOW TABLES;

-- Describe table
DESCRIBE table_name;
DESCRIBE FORMATTED table_name;

-- Create table
CREATE TABLE users (
  id INT,
  name STRING,
  age INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Load data
LOAD DATA LOCAL INPATH '/path/file.csv'
INTO TABLE users;

-- Drop table
DROP TABLE IF EXISTS users;

-- Truncate table
TRUNCATE TABLE users;
```

### Query Operations

```sql
-- Basic select
SELECT * FROM table_name LIMIT 10;

-- Filtering
SELECT * FROM table_name WHERE age > 30;

-- Aggregation
SELECT COUNT(*) FROM table_name;
SELECT AVG(age) FROM table_name;

-- Group by
SELECT department, AVG(salary)
FROM employees
GROUP BY department;

-- Join
SELECT * FROM table1 t1
JOIN table2 t2 ON t1.id = t2.id;

-- Order by
SELECT * FROM table_name ORDER BY name ASC LIMIT 10;

-- Distinct
SELECT DISTINCT department FROM employees;
```

### Performance

```sql
-- Set reduce tasks
SET mapreduce.job.reduces=4;

-- Enable parallel execution
SET hive.exec.parallel=true;

-- Show execution plan
EXPLAIN SELECT * FROM table_name;
```

## HBase Commands

### Connect to HBase

```bash
# HBase shell
docker-compose exec hbase-master hbase shell

# Check HBase status
echo status | hbase shell
```

### Admin Operations

```bash
# List tables
list

# Create table
create 'users', 'profile', 'contact'

# Describe table
describe 'users'

# Disable table (before modify)
disable 'users'

# Drop table
drop 'users'

# Truncate table
truncate 'users'

# Enable table
enable 'users'
```

### Data Operations

```bash
# Insert data
put 'users', 'user1', 'profile:name', 'John Doe'
put 'users', 'user1', 'profile:age', '30'
put 'users', 'user1', 'contact:email', 'john@example.com'

# Get row
get 'users', 'user1'

# Get specific column family
get 'users', 'user1', 'profile'

# Get specific cell
get 'users', 'user1', 'profile:name'

# Scan table
scan 'users'

# Scan with limit
scan 'users', {LIMIT => 10}

# Scan with columns
scan 'users', {COLUMNS => 'profile'}

# Count rows
count 'users'

# Delete cell
delete 'users', 'user1', 'contact:email'

# Delete row
deleteall 'users', 'user1'

# Get table size
size 'users'
```

## Pig Commands

### Running Pig Scripts

```bash
# Interactive mode (Grunt)
docker-compose exec namenode pig

# Batch mode
docker-compose exec namenode pig script.pig

# Script from HDFS
docker-compose exec namenode pig hdfs:///scripts/script.pig
```

### Pig Latin Commands

```pig
-- Load data
data = LOAD '/input/file.txt' AS (line:chararray);

-- Transform
words = FOREACH data GENERATE TOKENIZE(line) as word;

-- Filter
filtered = FILTER words BY word != '';

-- Group
grouped = GROUP words BY word;

-- Count
counts = FOREACH grouped GENERATE group, COUNT(words);

-- Sort
sorted = ORDER counts BY $1 DESC;

-- Store
STORE sorted INTO '/output/';

-- Display
DUMP sorted;
```

## Sqoop Commands

### Import Operations

```bash
# Basic import
sqoop import \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --table table_name \
  --target-dir /hdfs/path

# Import with WHERE clause
sqoop import \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --table table_name \
  --where "age > 30" \
  --target-dir /hdfs/path

# Import specific columns
sqoop import \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --table table_name \
  --columns "id,name,email" \
  --target-dir /hdfs/path

# Parallel import
sqoop import \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --table table_name \
  --num-mappers 4 \
  --split-by id \
  --target-dir /hdfs/path
```

### Export Operations

```bash
# Basic export
sqoop export \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --table table_name \
  --export-dir /hdfs/path
```

### Utility Commands

```bash
# List tables
sqoop list-tables \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass

# List databases
sqoop list-databases \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass

# Evaluate query
sqoop eval \
  --connect jdbc:mysql://host/db \
  --username user \
  --password pass \
  --query "SELECT * FROM table LIMIT 5"
```

## Administrative Commands

### Monitoring

```bash
# Check cluster status
hadoop dfsadmin -report

# NameNode info
hadoop dfsadmin -printTopology

# Datanode decommission
hadoop dfsadmin -decommission datanode_host

# Safemode
hdfs dfsadmin -safemode status
hdfs dfsadmin -safemode leave
hdfs dfsadmin -safemode enter

# HA status (if configured)
hdfs haadmin -getServiceState ha-namenode1
```

### Performance Tuning

```bash
# Check JVM settings
hadoop version

# Memory usage
jps -m

# View configuration
hadoop conf core-site.xml
```

## Quick Tips

1. **Always set JAVA_HOME**:
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
   ```

2. **Check file existence before processing**:
   ```bash
   hadoop fs -test -e /path && echo "exists" || echo "not found"
   ```

3. **Monitor long-running jobs**:
   ```bash
   watch 'yarn application -list'
   ```

4. **View recent logs efficiently**:
   ```bash
   docker-compose logs --tail=100 -f servicename
   ```

5. **Run commands from local machine via docker-compose**:
   ```bash
   docker-compose exec namenode hadoop fs -ls /
   ```

## Web UIs Quick Links

| Component | URL | Port |
|-----------|-----|------|
| NameNode | http://localhost:9870 | 9870 |
| ResourceManager | http://localhost:8088 | 8088 |
| HistoryServer | http://localhost:19888 | 19888 |
| HiveServer2 | http://localhost:10002 | 10002 |
| HBase Master | http://localhost:16010 | 16010 |
| ZooKeeper | N/A | 2181 |
| MariaDB | N/A | 3306 |
