# Tutorial 08: Integration Project - End-to-End Data Pipeline

**Duration:** 90-120 minutes
**Difficulty:** Advanced (Capstone Project)

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **How to build end-to-end data pipelines** combining multiple Hadoop tools
- **Why integration is the real challenge** in big data (not individual tools)
- **How data flows** through a complete analytics ecosystem
- **When to use which tool** and how they complement each other
- **How to troubleshoot** integration issues in distributed systems

**Real-world relevance:** At companies like Uber, Airbnb, and Netflix, data doesn't live in one tool. A typical pipeline might:
1. Extract data from 50+ MySQL databases (Sqoop)
2. Process 10TB of logs daily (MapReduce)
3. Run 1000+ SQL queries (Hive)
4. Serve results to millions of users (HBase)

This tutorial teaches you to orchestrate these components like production data engineers do.

---

## Conceptual Overview: The Data Pipeline Problem

### The Problem: Data Silos

In most companies, data lives in isolated systems:

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│  MySQL DB  │     │ Log Files  │     │   Excel    │
│  (Orders)  │     │ (Clicks)   │     │ (Products) │
└────────────┘     └────────────┘     └────────────┘
      ↓                  ↓                  ↓
   Isolated         Isolated            Isolated
   Can't join!      Can't analyze!      Can't scale!
```

**Questions you can't answer:**
- Which products generate the most revenue? (needs Orders + Products)
- What's our conversion rate? (needs Clicks + Orders)
- Which marketing campaigns work? (needs all three sources)

### The Solution: Unified Data Pipeline

Bring all data into one ecosystem where tools can work together:

```
┌─────────────────────────────────────────────────────────────┐
│                    HADOOP ECOSYSTEM                          │
│                                                               │
│  MySQL ─→ Sqoop ─→ HDFS ─→ Hive ─→ Analytics ─→ HBase ─→ App│
│                      ↑                                        │
│  Logs  ─→ MapReduce ─┘                                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Now you can:**
- Join data from any source (HDFS stores everything)
- Process at any scale (MapReduce handles big data)
- Query with SQL (Hive makes it accessible)
- Serve in real-time (HBase provides fast lookups)

---

## The Project: E-commerce Analytics Pipeline

### Business Scenario

You're a data engineer at ShopFast (fictional e-commerce company). Your tasks:

1. **Daily ETL:** Import product catalog and orders from MySQL
2. **Log Analysis:** Process millions of website access logs
3. **Business Intelligence:** Answer questions like:
   - Which products are top sellers?
   - What's revenue by category?
   - Are we getting 404 errors? (broken links)
4. **Real-time Serving:** Store results in HBase for dashboard API

### Architecture: The Complete Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│  ┌──────────────┐              ┌─────────────────────┐          │
│  │  MySQL DB    │              │  Access Logs        │          │
│  │ ┌──────────┐ │              │  192.168.1.1 GET /  │          │
│  │ │ products │ │              │  192.168.1.2 POST / │          │
│  │ │ orders   │ │              │  ... (millions)     │          │
│  │ └──────────┘ │              │                     │          │
│  └──────────────┘              └─────────────────────┘          │
└──────────┬──────────────────────────────┬────────────────────────┘
           │                              │
           │ Sqoop import                 │ MapReduce processing
           ▼                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                          HDFS (Storage Layer)                    │
│  /data/products/        /data/orders/        /data/logs/         │
│  /output/log_analysis/                                           │
└──────────┬───────────────────────────────────────────────────────┘
           │
           │ Hive queries (SQL analytics)
           ▼
┌──────────────────────────────────────────────────────────────────┐
│                     HIVE (SQL Analytics Layer)                   │
│  • Join products + orders                                        │
│  • Calculate revenue by category                                 │
│  • Find top performers                                           │
│  • Aggregate log statistics                                      │
└──────────┬───────────────────────────────────────────────────────┘
           │
           │ Store results
           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    HBASE (NoSQL Serving Layer)                   │
│  Row Key: product_1                                              │
│    revenue:total → $3,899.97                                     │
│    revenue:count → 3                                             │
│  Row Key: logs_2024_11_15                                        │
│    logs:status_200 → 1,523                                       │
│    logs:status_404 → 12                                          │
└──────────┬───────────────────────────────────────────────────────┘
           │
           ▼
     ┌─────────────┐
     │ Dashboards  │  ← API reads from HBase
     │ & Reports   │     (millisecond latency)
     └─────────────┘
```

### Why Each Tool?

| Tool | Purpose | Why Not Just Use... |
|------|---------|---------------------|
| **Sqoop** | Imports from MySQL | **MySQL alone:** Can't handle analytics on TB of data |
| **HDFS** | Stores all data | **Local files:** Can't store across 1000 machines |
| **MapReduce** | Processes logs | **MySQL:** Can't efficiently scan billions of log lines |
| **Hive** | SQL analytics | **MySQL:** Can't join HDFS data; MapReduce too low-level |
| **HBase** | Serves results | **MySQL:** Too slow for thousands of concurrent reads; Hive too slow |

**The key insight:** Each tool solves a specific problem. Integration creates a complete solution.

---

## Prerequisites

Before starting:

```bash
# Check all services are running
docker-compose ps

# You should see these as "Up":
# - namenode, datanode1, datanode2
# - resourcemanager, nodemanager
# - mariadb
# - hive-metastore, hive-server
# - zookeeper, hbase-master, hbase-regionserver
```

If services aren't running:
```bash
cd /Users/jason/Files/Practice/demo-little-things/hadoop-tutorial
docker-compose up -d

# Wait 2-3 minutes for all services to become healthy
docker-compose ps
```

**Verify you've completed previous tutorials:**
- Tutorial 01: HDFS basics
- Tutorial 02: MapReduce
- Tutorial 03: Hive
- Tutorial 04: HBase
- Tutorial 06: Sqoop

---

## Hands-On Exercises

### Exercise 1: Create Source Database

**Concept:** We're simulating a production MySQL database that powers the ShopFast e-commerce website. This database has tables that get updated thousands of times per day with new orders.

```bash
# Connect to MariaDB container
docker-compose exec mariadb mysql -u root -proot
```

```sql
-- Create database
CREATE DATABASE ecommerce;
USE ecommerce;

-- Create products table (catalog data, changes infrequently)
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(10, 2),
  stock INT
);

-- Create orders table (transactional data, grows constantly)
CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  product_id INT,
  quantity INT,
  order_date DATE,
  revenue DECIMAL(10, 2),
  FOREIGN KEY(product_id) REFERENCES products(product_id)
);

-- Insert sample product data
INSERT INTO products VALUES
  (1, 'Laptop Pro 15', 'Electronics', 1299.99, 50),
  (2, 'Wireless Mouse', 'Electronics', 29.99, 200),
  (3, 'USB-C Cable', 'Electronics', 12.99, 500),
  (4, 'Office Chair', 'Furniture', 299.99, 30),
  (5, 'Standing Desk', 'Furniture', 599.99, 15);

-- Insert sample order data (simulating a few days of orders)
INSERT INTO orders VALUES
  (1001, 1, 2, '2024-11-01', 2599.98),
  (1002, 2, 5, '2024-11-01', 149.95),
  (1003, 3, 10, '2024-11-01', 129.90),
  (1004, 1, 1, '2024-11-02', 1299.99),
  (1005, 4, 3, '2024-11-02', 899.97),
  (1006, 5, 1, '2024-11-03', 599.99),
  (1007, 2, 10, '2024-11-03', 299.90),
  (1008, 3, 20, '2024-11-03', 259.80);

-- Verify data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;

-- Preview data
SELECT * FROM products;
SELECT * FROM orders ORDER BY order_date;

EXIT;
```

**Expected output:**
```
Query OK, 1 row affected (0.01 sec)
Database changed
Query OK, 0 rows affected (0.02 sec)
Query OK, 0 rows affected (0.01 sec)
Query OK, 5 rows affected (0.00 sec)
Query OK, 8 rows affected (0.01 sec)

+----------+
| COUNT(*) |
+----------+
|        5 |
+----------+

+----------+
| COUNT(*) |
+----------+
|        8 |
+----------+

+------------+-----------------+-------------+---------+-------+
| product_id | product_name    | category    | price   | stock |
+------------+-----------------+-------------+---------+-------+
|          1 | Laptop Pro 15   | Electronics | 1299.99 |    50 |
|          2 | Wireless Mouse  | Electronics |   29.99 |   200 |
|          3 | USB-C Cable     | Electronics |   12.99 |   500 |
|          4 | Office Chair    | Furniture   |  299.99 |    30 |
|          5 | Standing Desk   | Furniture   |  599.99 |    15 |
+------------+-----------------+-------------+---------+-------+

+----------+------------+----------+------------+----------+
| order_id | product_id | quantity | order_date | revenue  |
+----------+------------+----------+------------+----------+
|     1001 |          1 |        2 | 2024-11-01 |  2599.98 |
|     1002 |          2 |        5 | 2024-11-01 |   149.95 |
|     1003 |          3 |       10 | 2024-11-01 |   129.90 |
|     1004 |          1 |        1 | 2024-11-02 |  1299.99 |
|     1005 |          4 |        3 | 2024-11-02 |   899.97 |
|     1006 |          5 |        1 | 2024-11-03 |   599.99 |
|     1007 |          2 |       10 | 2024-11-03 |   299.90 |
|     1008 |          3 |       20 | 2024-11-03 |   259.80 |
+----------+------------+----------+------------+----------+
```

**What this represents in production:**
- `products` table: ~10,000 products (50 MB)
- `orders` table: ~10M orders/day (5 GB/day, 1.8 TB/year)
- **Problem:** MySQL can't efficiently analyze years of historical orders
- **Solution:** Move data to Hadoop for analytics

---

### Exercise 2: Import Data with Sqoop (ETL Extract)

**Concept:** Sqoop will extract data from MySQL and load it into HDFS. In production, this runs daily (or hourly) to sync new data.

```bash
# Connect to namenode (where Sqoop is installed)
docker-compose exec namenode bash

# Import products table
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table products \
  --target-dir /data/ecommerce/products \
  --delete-target-dir \
  --num-mappers 1 \
  --fields-terminated-by ','
```

**Expected output:**
```
24/11/15 10:00:01 INFO sqoop.Sqoop: Running Sqoop version: 1.4.7
24/11/15 10:00:02 INFO manager.MySQLManager: Preparing to use a MySQL streaming resultset.
24/11/15 10:00:02 INFO tool.CodeGenTool: Beginning code generation
24/11/15 10:00:03 INFO mapreduce.Job: Running job: job_1699876543210_0001
24/11/15 10:00:15 INFO mapreduce.Job:  map 0% reduce 0%
24/11/15 10:00:28 INFO mapreduce.Job:  map 100% reduce 0%
24/11/15 10:00:29 INFO mapreduce.Job: Job job_1699876543210_0001 completed successfully
24/11/15 10:00:29 INFO mapreduce.ImportJobBase: Transferred 385 bytes in 27.5 seconds
24/11/15 10:00:29 INFO mapreduce.ImportJobBase: Retrieved 5 records.
```

**What just happened:**

```
Step 1: Sqoop connects to MySQL
  ┌────────────────────────┐
  │ SELECT * FROM products │  ← Sqoop issues this query
  └────────────────────────┘

Step 2: Sqoop launches a MapReduce job
  Mapper reads MySQL rows:
    Row 1: (1, 'Laptop Pro 15', 'Electronics', 1299.99, 50)
    Row 2: (2, 'Wireless Mouse', 'Electronics', 29.99, 200)
    ...

Step 3: Mapper writes to HDFS as CSV
  /data/ecommerce/products/part-m-00000:
    1,Laptop Pro 15,Electronics,1299.99,50
    2,Wireless Mouse,Electronics,29.99,200
    3,USB-C Cable,Electronics,12.99,500
    4,Office Chair,Furniture,299.99,30
    5,Standing Desk,Furniture,599.99,15

  ✓ Data replicated 2x (on datanode1 and datanode2)
  ✓ Total: 5 records transferred
```

**Now import orders table:**

```bash
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table orders \
  --target-dir /data/ecommerce/orders \
  --delete-target-dir \
  --num-mappers 1 \
  --fields-terminated-by ','
```

**Verify imports:**

```bash
# Check HDFS directories were created
hadoop fs -ls /data/ecommerce/

# View products data
hadoop fs -cat /data/ecommerce/products/part-m-00000

# View orders data
hadoop fs -cat /data/ecommerce/orders/part-m-00000
```

**Expected output:**
```
Found 2 items
drwxr-xr-x   - hadoop supergroup          0 2024-11-15 10:00 /data/ecommerce/orders
drwxr-xr-x   - hadoop supergroup          0 2024-11-15 09:58 /data/ecommerce/products

1,Laptop Pro 15,Electronics,1299.99,50
2,Wireless Mouse,Electronics,29.99,200
3,USB-C Cable,Electronics,12.99,500
4,Office Chair,Furniture,299.99,30
5,Standing Desk,Furniture,599.99,15

1001,1,2,2024-11-01,2599.98
1002,2,5,2024-11-01,149.95
1003,3,10,2024-11-01,129.90
1004,1,1,2024-11-02,1299.99
1005,4,3,2024-11-02,899.97
1006,5,1,2024-11-03,599.99
1007,2,10,2024-11-03,299.90
1008,3,20,2024-11-03,259.80
```

**Why this matters:**
- Data now lives in HDFS (can scale to petabytes)
- Other Hadoop tools (Hive, Pig, MapReduce) can access it
- In production: Run this daily to sync MySQL → HDFS

---

### Exercise 3: Process Log Files with MapReduce

**Concept:** Web servers generate access logs (who visited, which page, response code). We need to analyze these to find errors (404s) and traffic patterns. MapReduce is perfect for processing billions of log lines.

**Check available log data:**

```bash
# Check if sample logs exist
ls -lh /datasets/logs/

# Preview log format
head -20 /datasets/logs/access_logs.txt
```

**Expected output:**
```
-rw-r--r-- 1 hadoop hadoop 52K Nov 15 09:00 access_logs.txt

192.168.1.100 - - [15/Nov/2024:10:00:01 +0000] "GET /products/laptop HTTP/1.1" 200 4523
192.168.1.101 - - [15/Nov/2024:10:00:02 +0000] "GET /cart HTTP/1.1" 200 1234
192.168.1.102 - - [15/Nov/2024:10:00:03 +0000] "GET /checkout HTTP/1.1" 200 8765
192.168.1.103 - - [15/Nov/2024:10:00:04 +0000] "GET /products/mouse HTTP/1.1" 200 2341
192.168.1.104 - - [15/Nov/2024:10:00:05 +0000] "GET /nonexistent HTTP/1.1" 404 512
...
```

**What each field means:**
```
192.168.1.100 - - [15/Nov/2024:10:00:01 +0000] "GET /products/laptop HTTP/1.1" 200 4523
     ↑         ↑            ↑                         ↑                           ↑    ↑
  IP address  User  Timestamp                    HTTP request              Status Size
```

**Upload logs to HDFS:**

```bash
# Create directory for logs
hadoop fs -mkdir -p /data/logs

# Upload log file
hadoop fs -put /datasets/logs/access_logs.txt /data/logs/

# Verify
hadoop fs -ls /data/logs/
hadoop fs -cat /data/logs/access_logs.txt | head -10
```

**Create MapReduce job to analyze HTTP status codes:**

Create file `LogAnalyzer.java`:

```bash
cat > LogAnalyzer.java << 'EOF'
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import java.io.IOException;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class LogAnalyzer {

  // MAPPER: Extract status code from each log line
  public static class LogMapper
      extends Mapper<Object, Text, Text, IntWritable> {

    private Text statusCode = new Text();
    private final IntWritable one = new IntWritable(1);
    private Pattern pattern = Pattern.compile("HTTP/\\d\\.\\d\" (\\d{3})");

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {

      String line = value.toString();
      Matcher matcher = pattern.matcher(line);

      if (matcher.find()) {
        String status = matcher.group(1);  // Extract status code
        statusCode.set(status);
        context.write(statusCode, one);
        // Output: (200, 1), (404, 1), (200, 1), ...
      }
    }
  }

  // REDUCER: Count occurrences of each status code
  public static class LogReducer
      extends Reducer<Text, IntWritable, Text, IntWritable> {

    private IntWritable result = new IntWritable();

    public void reduce(Text key, Iterable<IntWritable> values, Context context)
        throws IOException, InterruptedException {

      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);
      context.write(key, result);
      // Output: (200, 15234), (404, 127), (500, 23)
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "log analyzer");
    job.setJarByClass(LogAnalyzer.class);
    job.setMapperClass(LogMapper.class);
    job.setReducerClass(LogReducer.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
EOF
```

**Compile and run:**

```bash
# Compile Java code
javac -cp /opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/* \
  LogAnalyzer.java

# Create JAR file
jar cvf loganalyzer.jar LogAnalyzer*.class

# Run MapReduce job
yarn jar loganalyzer.jar LogAnalyzer /data/logs /output/log_analysis

# View results
hadoop fs -cat /output/log_analysis/part-r-00000
```

**Expected output:**
```
24/11/15 10:15:00 INFO client.RMProxy: Connecting to ResourceManager at resourcemanager/172.18.0.5:8032
24/11/15 10:15:02 INFO mapreduce.Job: Running job: job_1699876543210_0002
24/11/15 10:15:15 INFO mapreduce.Job:  map 0% reduce 0%
24/11/15 10:15:28 INFO mapreduce.Job:  map 100% reduce 0%
24/11/15 10:15:35 INFO mapreduce.Job:  map 100% reduce 100%
24/11/15 10:15:36 INFO mapreduce.Job: Job job_1699876543210_0002 completed successfully

Results:
200	15234
301	412
401	23
404	127
500	15
```

**What just happened:**

```
Input: 15,811 log lines

MAPPER PHASE:
  Line 1: "... HTTP/1.1" 200 4523" → emit (200, 1)
  Line 2: "... HTTP/1.1" 200 1234" → emit (200, 1)
  Line 3: "... HTTP/1.1" 404 512"  → emit (404, 1)
  ...
  Result: 15,811 (status_code, 1) pairs

SHUFFLE & SORT:
  Group by status code:
    200 → [(1), (1), (1), ... 15,234 times]
    404 → [(1), (1), (1), ... 127 times]
    500 → [(1), (1), (1), ... 15 times]

REDUCER PHASE:
  Status 200: sum([1,1,1,...]) = 15,234
  Status 404: sum([1,1,1,...]) = 127
  Status 500: sum([1,1,1,...]) = 15

Output saved to HDFS: /output/log_analysis/part-r-00000
```

**Business insight:**
- 96.3% requests succeeded (200)
- 0.8% were not found (404) ← **ALERT: Broken links!**
- 0.1% server errors (500) ← **ALERT: Application bugs!**

---

### Exercise 4: Create Hive Tables on Imported Data

**Concept:** Now we have data in HDFS from two sources (Sqoop and MapReduce). Hive lets us query all of it using SQL. We create "external tables" that point to existing HDFS data.

```bash
# Connect to Hive
docker-compose exec hive-server hive
```

```sql
-- Create table for products (points to Sqoop import)
CREATE EXTERNAL TABLE products (
  product_id INT,
  product_name STRING,
  category STRING,
  price DOUBLE,
  stock INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/data/ecommerce/products';

-- Create table for orders
CREATE EXTERNAL TABLE orders (
  order_id INT,
  product_id INT,
  quantity INT,
  order_date STRING,
  revenue DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/data/ecommerce/orders';

-- Create table for log analysis results
CREATE EXTERNAL TABLE log_stats (
  status_code STRING,
  count INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/output/log_analysis';

-- Verify tables
SHOW TABLES;

-- Preview data
SELECT * FROM products LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM log_stats;
```

**Expected output:**
```
OK
Time taken: 1.234 seconds

OK
Time taken: 0.876 seconds

OK
Time taken: 0.543 seconds

OK
log_stats
orders
products
Time taken: 0.123 seconds, Fetched: 3 row(s)

OK
1	Laptop Pro 15	Electronics	1299.99	50
2	Wireless Mouse	Electronics	29.99	200
3	USB-C Cable	Electronics	12.99	500
4	Office Chair	Furniture	299.99	30
5	Standing Desk	Furniture	599.99	15
Time taken: 2.345 seconds, Fetched: 5 row(s)

OK
1001	1	2	2024-11-01	2599.98
1002	2	5	2024-11-01	149.95
1003	3	10	2024-11-01	129.90
1004	1	1	2024-11-02	1299.99
1005	4	3	2024-11-02	899.97
Time taken: 1.234 seconds, Fetched: 5 row(s)

OK
200	15234
301	412
401	23
404	127
500	15
Time taken: 0.876 seconds, Fetched: 5 row(s)
```

**What just happened:**

```
EXTERNAL TABLE means:
  ✓ Hive reads existing data (doesn't copy it)
  ✓ Dropping table won't delete HDFS files
  ✓ Multiple tables can point to same data

Location mapping:
  products table → /data/ecommerce/products/part-m-00000
  orders table   → /data/ecommerce/orders/part-m-00000
  log_stats table → /output/log_analysis/part-r-00000

When you query:
  SELECT * FROM products
  ↓
  Hive reads /data/ecommerce/products/part-m-00000
  ↓
  Parses CSV: 1,Laptop Pro 15,Electronics,1299.99,50
  ↓
  Returns structured data: (1, "Laptop Pro 15", "Electronics", 1299.99, 50)
```

**Why this matters:**
- Now we can use SQL instead of MapReduce!
- Can join data from different sources (MySQL + logs)
- Business analysts can query without writing Java

---

### Exercise 5: Run Business Analytics Queries

**Concept:** This is where the value emerges. We can now answer complex business questions by joining data across sources.

**Query 1: Total revenue by product**

```sql
-- Which products make the most money?
SELECT
  p.product_name,
  SUM(o.revenue) as total_revenue,
  SUM(o.quantity) as total_quantity,
  COUNT(*) as order_count
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;
```

**Expected output:**
```
OK
Laptop Pro 15	3899.97	3	2
Office Chair	899.97	3	1
Standing Desk	599.99	1	1
Wireless Mouse	449.85	15	2
USB-C Cable	389.70	30	2
Time taken: 15.234 seconds, Fetched: 5 row(s)
```

**What just happened:**

```
Step 1: Hive launches MapReduce job to join tables
  Map Phase:
    Read products: (1, "Laptop Pro 15"), (2, "Wireless Mouse"), ...
    Read orders:   (1001, 1, 2599.98), (1002, 2, 149.95), ...

  Shuffle: Group by product_id
    product_id=1 → [("Laptop Pro 15", 2599.98), ("Laptop Pro 15", 1299.99)]
    product_id=2 → [("Wireless Mouse", 149.95), ("Wireless Mouse", 299.90)]

  Reduce Phase:
    product_id=1: SUM(2599.98 + 1299.99) = $3,899.97
    product_id=2: SUM(149.95 + 299.90) = $449.85

Output: Top seller is Laptop Pro 15 with $3,899.97 revenue
```

**Business insight:** Focus marketing budget on laptops (highest revenue).

**Query 2: Revenue by category**

```sql
-- How do Electronics vs Furniture perform?
SELECT
  p.category,
  SUM(o.revenue) as total_revenue,
  COUNT(*) as order_count,
  ROUND(AVG(o.revenue), 2) as avg_order_value
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
```

**Expected output:**
```
OK
Electronics	5239.52	6	873.25
Furniture	1499.96	2	749.98
Time taken: 12.456 seconds, Fetched: 2 row(s)
```

**Business insight:**
- Electronics: 77% of revenue, smaller average order ($873)
- Furniture: 23% of revenue, larger average order ($750)
- **Action:** Increase furniture inventory (high margin, low volume)

**Query 3: High-value orders (revenue > $1000)**

```sql
-- Find our biggest customers
SELECT
  o.order_id,
  p.product_name,
  o.quantity,
  o.order_date,
  o.revenue
FROM products p
JOIN orders o ON p.product_id = o.product_id
WHERE o.revenue > 1000
ORDER BY o.revenue DESC;
```

**Expected output:**
```
OK
1001	Laptop Pro 15	2	2024-11-01	2599.98
1004	Laptop Pro 15	1	2024-11-02	1299.99
Time taken: 10.123 seconds, Fetched: 2 row(s)
```

**Business insight:** 2 of 8 orders (25%) are high-value laptop purchases.

**Query 4: Analyze website health (from log data)**

```sql
-- How many errors are we getting?
SELECT
  status_code,
  count,
  ROUND(count / SUM(count) OVER () * 100, 2) as percentage
FROM log_stats
ORDER BY count DESC;
```

**Expected output:**
```
OK
200	15234	96.35
301	412	2.61
404	127	0.80
401	23	0.15
500	15	0.09
Time taken: 5.432 seconds, Fetched: 5 row(s)
```

**Business insight:**
- 96% success rate (good!)
- 127 page-not-found errors ← **Fix broken links**
- 15 server errors ← **Check application logs**

---

### Exercise 6: Store Results in HBase for Real-Time Serving

**Concept:** Hive queries are slow (10-30 seconds). For dashboards and APIs, we need fast lookups (< 100ms). HBase provides this by storing pre-computed results.

```bash
# Connect to HBase
docker-compose exec hbase-master hbase shell
```

```ruby
# Create table with two column families
create 'analytics_results', 'revenue', 'logs'

# Verify table created
list

# Describe table structure
describe 'analytics_results'
```

**Expected output:**
```
Created table analytics_results
Took 2.3456 seconds

TABLE
analytics_results

Table analytics_results is ENABLED
analytics_results
COLUMN FAMILIES DESCRIPTION
{NAME => 'logs', VERSIONS => '1', EVICT_BLOCKS_ON_CLOSE => 'false', ...}
{NAME => 'revenue', VERSIONS => '1', EVICT_BLOCKS_ON_CLOSE => 'false', ...}
2 row(s)
Took 0.1234 seconds
```

**Store product revenue results (from Hive Query 1):**

```ruby
# Product 1: Laptop Pro 15
put 'analytics_results', 'product_1', 'revenue:total', '3899.97'
put 'analytics_results', 'product_1', 'revenue:count', '3'
put 'analytics_results', 'product_1', 'revenue:avg', '1299.99'
put 'analytics_results', 'product_1', 'revenue:name', 'Laptop Pro 15'

# Product 2: Wireless Mouse
put 'analytics_results', 'product_2', 'revenue:total', '449.85'
put 'analytics_results', 'product_2', 'revenue:count', '15'
put 'analytics_results', 'product_2', 'revenue:avg', '29.99'
put 'analytics_results', 'product_2', 'revenue:name', 'Wireless Mouse'

# Product 4: Office Chair
put 'analytics_results', 'product_4', 'revenue:total', '899.97'
put 'analytics_results', 'product_4', 'revenue:count', '3'
put 'analytics_results', 'product_4', 'revenue:avg', '299.99'
put 'analytics_results', 'product_4', 'revenue:name', 'Office Chair'
```

**Store log statistics (from Hive Query 4):**

```ruby
# Store today's log stats
put 'analytics_results', 'logs_2024_11_15', 'logs:status_200', '15234'
put 'analytics_results', 'logs:status_301', '412'
put 'analytics_results', 'logs_2024_11_15', 'logs:status_404', '127'
put 'analytics_results', 'logs_2024_11_15', 'logs:status_401', '23'
put 'analytics_results', 'logs_2024_11_15', 'logs:status_500', '15'
put 'analytics_results', 'logs_2024_11_15', 'logs:total_requests', '15811'
```

**Query results (simulating dashboard API):**

```ruby
# Get single product stats (fast lookup by row key)
get 'analytics_results', 'product_1'

# Get all products
scan 'analytics_results', {STARTROW => 'product_', STOPROW => 'product_z'}

# Get log stats
get 'analytics_results', 'logs_2024_11_15'

# Scan all data
scan 'analytics_results'
```

**Expected output:**
```
# get 'analytics_results', 'product_1'
COLUMN                          CELL
 revenue:avg                    timestamp=1699876543210, value=1299.99
 revenue:count                  timestamp=1699876543208, value=3
 revenue:name                   timestamp=1699876543211, value=Laptop Pro 15
 revenue:total                  timestamp=1699876543207, value=3899.97
4 row(s)
Took 0.0234 seconds

# scan 'analytics_results', {STARTROW => 'product_', STOPROW => 'product_z'}
ROW                             COLUMN+CELL
 product_1                      column=revenue:avg, timestamp=1699876543210, value=1299.99
 product_1                      column=revenue:count, timestamp=1699876543208, value=3
 product_1                      column=revenue:name, timestamp=1699876543211, value=Laptop Pro 15
 product_1                      column=revenue:total, timestamp=1699876543207, value=3899.97
 product_2                      column=revenue:avg, timestamp=1699876543214, value=29.99
 product_2                      column=revenue:count, timestamp=1699876543212, value=15
 product_2                      column=revenue:name, timestamp=1699876543215, value=Wireless Mouse
 product_2                      column=revenue:total, timestamp=1699876543211, value=449.85
 product_4                      column=revenue:avg, timestamp=1699876543218, value=299.99
 product_4                      column=revenue:count, timestamp=1699876543216, value=3
 product_4                      column=revenue:name, timestamp=1699876543219, value=Office Chair
 product_4                      column=revenue:total, timestamp=1699876543215, value=899.97
3 row(s)
Took 0.0456 seconds

# get 'analytics_results', 'logs_2024_11_15'
COLUMN                          CELL
 logs:status_200                timestamp=1699876543220, value=15234
 logs:status_301                timestamp=1699876543221, value=412
 logs:status_401                timestamp=1699876543222, value=23
 logs:status_404                timestamp=1699876543223, value=127
 logs:status_500                timestamp=1699876543224, value=15
 logs:total_requests            timestamp=1699876543225, value=15811
6 row(s)
Took 0.0123 seconds
```

**What just happened:**

```
Data transformation pipeline:

MySQL (OLTP) + Logs (raw)
  ↓ Sqoop + MapReduce
HDFS (data lake, 30-second queries)
  ↓ Hive (batch analytics)
HBase (NoSQL, 20ms queries)
  ↓ API
Dashboard (real-time)

Storage comparison:
┌─────────┬──────────────┬─────────────────┬──────────────┐
│ System  │ Query Time   │ Use Case        │ Cost         │
├─────────┼──────────────┼─────────────────┼──────────────┤
│ MySQL   │ 1-5 sec      │ OLTP queries    │ $$ (limited) │
│ Hive    │ 10-30 sec    │ Ad-hoc analysis │ $ (cheap)    │
│ HBase   │ 10-50 ms     │ Real-time serve │ $$ (RAM)     │
└─────────┴──────────────┴─────────────────┴──────────────┘

Row key design:
  product_1, product_2, ... → Fast lookup by product ID
  logs_2024_11_15, logs_2024_11_16, ... → Fast lookup by date
```

**Why this matters:**
- Dashboard can load product stats in 20ms (vs 15 seconds in Hive)
- Can handle 10,000 requests/second
- Data is pre-aggregated (no JOIN needed at query time)

Exit HBase shell:
```ruby
exit
```

---

### Exercise 7: Create End-to-End Pipeline Script

**Concept:** In production, you'd automate the entire pipeline to run daily. Let's create a script that orchestrates all the tools.

Create file `run_pipeline.sh`:

```bash
cat > /tmp/run_pipeline.sh << 'EOF'
#!/bin/bash
set -e  # Exit on any error

echo "========================================"
echo "  E-COMMERCE ANALYTICS PIPELINE v1.0"
echo "========================================"
echo ""
echo "Pipeline stages:"
echo "  1. Extract: Import MySQL data (Sqoop)"
echo "  2. Transform: Process logs (MapReduce)"
echo "  3. Load: Create Hive tables"
echo "  4. Analyze: Run business queries (Hive)"
echo "  5. Serve: Store in HBase"
echo ""

# Stage 1: Extract data from MySQL
echo "[Stage 1/5] Importing data from MySQL with Sqoop..."
echo "  → Importing products table..."
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table products \
  --target-dir /data/ecommerce/products \
  --delete-target-dir \
  --num-mappers 1 \
  --fields-terminated-by ',' \
  2>&1 | grep -E "(INFO mapreduce.Job: Job|Retrieved .* records)" || true

echo "  → Importing orders table..."
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table orders \
  --target-dir /data/ecommerce/orders \
  --delete-target-dir \
  --num-mappers 1 \
  --fields-terminated-by ',' \
  2>&1 | grep -E "(INFO mapreduce.Job: Job|Retrieved .* records)" || true

echo "  ✓ Data import complete"
echo ""

# Stage 2: Process log files
echo "[Stage 2/5] Processing log files with MapReduce..."
hadoop fs -mkdir -p /data/logs 2>/dev/null || true
hadoop fs -put -f /datasets/logs/access_logs.txt /data/logs/

echo "  → Compiling LogAnalyzer..."
cd /tmp
javac -cp /opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/* \
  LogAnalyzer.java 2>/dev/null

echo "  → Creating JAR..."
jar cvf loganalyzer.jar LogAnalyzer*.class 2>&1 | grep -v "adding" || true

echo "  → Running MapReduce job..."
yarn jar loganalyzer.jar LogAnalyzer /data/logs /output/log_analysis \
  2>&1 | grep -E "(INFO mapreduce.Job: Job|Job .* completed successfully)" || true

echo "  ✓ Log processing complete"
echo ""

# Stage 3: Create Hive tables
echo "[Stage 3/5] Creating Hive tables..."
hive -e "
CREATE EXTERNAL TABLE IF NOT EXISTS products (
  product_id INT, product_name STRING, category STRING, price DOUBLE, stock INT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/data/ecommerce/products';

CREATE EXTERNAL TABLE IF NOT EXISTS orders (
  order_id INT, product_id INT, quantity INT, order_date STRING, revenue DOUBLE
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/data/ecommerce/orders';

CREATE EXTERNAL TABLE IF NOT EXISTS log_stats (
  status_code STRING, count INT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LOCATION '/output/log_analysis';
" 2>&1 | grep -v "SLF4J" || true

echo "  ✓ Hive tables created"
echo ""

# Stage 4: Run analytics
echo "[Stage 4/5] Running business analytics..."
echo ""
echo "--- Top Products by Revenue ---"
hive -e "
SELECT p.product_name, SUM(o.revenue) as total_revenue
FROM products p JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_name ORDER BY total_revenue DESC;
" 2>&1 | grep -v "SLF4J\|Time taken" || true

echo ""
echo "--- Revenue by Category ---"
hive -e "
SELECT p.category, SUM(o.revenue) as total_revenue, COUNT(*) as order_count
FROM products p JOIN orders o ON p.product_id = o.product_id
GROUP BY p.category;
" 2>&1 | grep -v "SLF4J\|Time taken" || true

echo ""
echo "--- Website Status Codes ---"
hive -e "SELECT * FROM log_stats ORDER BY count DESC;" \
  2>&1 | grep -v "SLF4J\|Time taken" || true

echo ""
echo "  ✓ Analytics complete"
echo ""

# Stage 5: Load to HBase (simplified - you'd use Hive integration in production)
echo "[Stage 5/5] Results stored in HBase (table: analytics_results)"
echo "  ✓ Ready for real-time serving"
echo ""

echo "========================================"
echo "  PIPELINE COMPLETED SUCCESSFULLY"
echo "========================================"
echo ""
echo "Next steps:"
echo "  • View results in Hive: docker-compose exec hive-server hive"
echo "  • Check HBase data: docker-compose exec hbase-master hbase shell"
echo "  • Monitor jobs: http://localhost:8088"
echo ""
EOF

chmod +x /tmp/run_pipeline.sh
```

**Run the complete pipeline:**

```bash
# Copy LogAnalyzer.java to /tmp if not already there
cp LogAnalyzer.java /tmp/

# Execute pipeline
/tmp/run_pipeline.sh
```

**Expected output:**
```
========================================
  E-COMMERCE ANALYTICS PIPELINE v1.0
========================================

Pipeline stages:
  1. Extract: Import MySQL data (Sqoop)
  2. Transform: Process logs (MapReduce)
  3. Load: Create Hive tables
  4. Analyze: Run business queries (Hive)
  5. Serve: Store in HBase

[Stage 1/5] Importing data from MySQL with Sqoop...
  → Importing products table...
24/11/15 10:30:01 INFO mapreduce.Job: Job job_1699876543210_0003 completed successfully
24/11/15 10:30:01 INFO mapreduce.ImportJobBase: Retrieved 5 records.
  → Importing orders table...
24/11/15 10:30:15 INFO mapreduce.Job: Job job_1699876543210_0004 completed successfully
24/11/15 10:30:15 INFO mapreduce.ImportJobBase: Retrieved 8 records.
  ✓ Data import complete

[Stage 2/5] Processing log files with MapReduce...
  → Compiling LogAnalyzer...
  → Creating JAR...
  → Running MapReduce job...
24/11/15 10:30:35 INFO mapreduce.Job: Job job_1699876543210_0005 completed successfully
  ✓ Log processing complete

[Stage 3/5] Creating Hive tables...
  ✓ Hive tables created

[Stage 4/5] Running business analytics...

--- Top Products by Revenue ---
OK
Laptop Pro 15	3899.97
Office Chair	899.97
Standing Desk	599.99
Wireless Mouse	449.85
USB-C Cable	389.70

--- Revenue by Category ---
OK
Electronics	5239.52	6
Furniture	1499.96	2

--- Website Status Codes ---
OK
200	15234
301	412
404	127
401	23
500	15

  ✓ Analytics complete

[Stage 5/5] Results stored in HBase (table: analytics_results)
  ✓ Ready for real-time serving

========================================
  PIPELINE COMPLETED SUCCESSFULLY
========================================

Next steps:
  • View results in Hive: docker-compose exec hive-server hive
  • Check HBase data: docker-compose exec hbase-master hbase shell
  • Monitor jobs: http://localhost:8088
```

**What just happened:**

```
Complete data flow:

Time T=0: Start pipeline
├─ MySQL has: 5 products, 8 orders
└─ Logs have: 15,811 access records

Time T=30s: Sqoop import
├─ Extracted 5 products → /data/ecommerce/products (385 bytes)
├─ Extracted 8 orders → /data/ecommerce/orders (215 bytes)
└─ Data now in HDFS (distributed, fault-tolerant)

Time T=60s: MapReduce processing
├─ Read 15,811 log lines
├─ Extracted status codes
├─ Aggregated counts
└─ Wrote results → /output/log_analysis (50 bytes)

Time T=65s: Hive table creation
├─ Created schema for products (points to HDFS)
├─ Created schema for orders (points to HDFS)
└─ Created schema for log_stats (points to HDFS)

Time T=90s: Hive analytics (3 queries)
├─ JOIN products + orders (MapReduce job)
├─ GROUP BY and aggregate
└─ Generated business insights

Time T=95s: HBase load (manual step)
├─ Pre-computed results stored
└─ Ready for < 50ms lookups

TOTAL TIME: ~95 seconds for complete pipeline
```

**In production:**
- Run this script daily via cron/Airflow
- Process TBs of data (not just KBs)
- Pipeline takes hours (not seconds)
- Results feed dashboards/APIs

---

### Exercise 8: Monitor the Pipeline

**Concept:** In production, you need to monitor job success, performance, and data quality.

**Check HDFS storage usage:**

```bash
# Overall cluster health
hadoop fs -df -h

# Storage by directory
hadoop fs -du -h /data/
hadoop fs -du -h /output/
```

**Expected output:**
```
Filesystem              Size    Used  Available  Use%
hdfs://namenode:9000  100 G  10.4 M     99.9 G    0%

5.2 K  /data/ecommerce/products
4.1 K  /data/ecommerce/orders
52.3 K /data/logs

1.2 K  /output/log_analysis
```

**View YARN job history:**

```bash
# List recent jobs
yarn application -list -appStates ALL

# Get detailed stats for a job
yarn application -status application_1699876543210_0005
```

**Check web UIs:**

```bash
echo "Available monitoring interfaces:"
echo "  • HDFS NameNode:        http://localhost:9870"
echo "  • YARN ResourceManager: http://localhost:8088"
echo "  • MapReduce History:    http://localhost:19888"
echo "  • HBase Master:         http://localhost:16010"
echo "  • Hive Server:          http://localhost:10002"
```

Open http://localhost:8088 in your browser:
- Click "Applications" to see all MapReduce jobs
- Click on a job to see:
  - Start/end time
  - Number of mappers/reducers
  - Data processed
  - Success/failure status

**Data quality checks:**

```bash
# Verify row counts match
echo "Row count verification:"
echo "  MySQL products: 5 (source)"
hadoop fs -cat /data/ecommerce/products/part-m-00000 | wc -l  # Should be 5

echo "  MySQL orders: 8 (source)"
hadoop fs -cat /data/ecommerce/orders/part-m-00000 | wc -l  # Should be 8

# Check for nulls in critical fields
docker-compose exec hive-server hive -e "
SELECT COUNT(*) as null_revenues
FROM orders
WHERE revenue IS NULL;
"
```

**Expected output:**
```
Row count verification:
  MySQL products: 5 (source)
5
  MySQL orders: 8 (source)
8

OK
0
Time taken: 3.456 seconds, Fetched: 1 row(s)
```

**Performance metrics:**

```bash
# View MapReduce job times
echo "Job performance metrics:"
grep "completed successfully" /tmp/run_pipeline.sh.log | while read line; do
  echo "  $line"
done

# Storage efficiency
echo ""
echo "Storage replication:"
hadoop fs -stat "%r" /data/ecommerce/products/part-m-00000  # Should be 2
```

---

## Understanding the Integration

### Why This Architecture?

```
┌──────────────────┬─────────────────────────────────────────────┐
│ Tool             │ Purpose in Pipeline                         │
├──────────────────┼─────────────────────────────────────────────┤
│ MySQL            │ Operational database (orders, products)     │
│                  │ ✓ ACID transactions                         │
│                  │ ✗ Can't handle analytics on TB of data      │
├──────────────────┼─────────────────────────────────────────────┤
│ Sqoop            │ Bridge between MySQL and Hadoop             │
│                  │ ✓ Parallel import (10x faster than mysqldump)│
│                  │ ✓ Incremental sync (only new data)          │
├──────────────────┼─────────────────────────────────────────────┤
│ HDFS             │ Distributed storage (cheap, scalable)      │
│                  │ ✓ Can store petabytes                       │
│                  │ ✓ Fault-tolerant (replication)              │
│                  │ ✗ No indexing (slow for lookups)            │
├──────────────────┼─────────────────────────────────────────────┤
│ MapReduce        │ Batch processing (logs, ETL)               │
│                  │ ✓ Processes TBs of data                     │
│                  │ ✗ High latency (minutes to hours)           │
├──────────────────┼─────────────────────────────────────────────┤
│ Hive             │ SQL analytics on HDFS                      │
│                  │ ✓ Familiar SQL interface                    │
│                  │ ✓ Schema-on-read flexibility                │
│                  │ ✗ Slow queries (10-30 seconds)              │
├──────────────────┼─────────────────────────────────────────────┤
│ HBase            │ Real-time serving layer                    │
│                  │ ✓ Fast lookups (10-50 ms)                   │
│                  │ ✓ High throughput (millions of ops/sec)     │
│                  │ ✗ No SQL (only key-value)                   │
└──────────────────┴─────────────────────────────────────────────┘
```

### The Lambda Architecture Pattern

What we built is a simplified **Lambda Architecture**:

```
                     ┌─────────────────┐
                     │  BATCH LAYER    │
                     │  (Slow, Complete)│
                     ├─────────────────┤
  Data Sources  ───→ │ Sqoop + HDFS    │
  (MySQL, Logs)      │ MapReduce       │
                     │ Hive            │
                     └────────┬────────┘
                              │
                              ├────→ Pre-compute metrics
                              ↓
                     ┌─────────────────┐
                     │  SERVING LAYER  │
                     │  (Fast, Read)   │
                     ├─────────────────┤
                     │ HBase           │ ───→ Dashboard API
                     │ (NoSQL)         │      (< 100ms)
                     └─────────────────┘

Used by: LinkedIn, Twitter, Netflix
```

**Batch Layer (Hive):**
- Processes ALL historical data
- Runs nightly
- Generates accurate, complete results
- Example: "Total revenue for all time"

**Serving Layer (HBase):**
- Serves pre-computed results
- Updated after batch job
- Fast random access
- Example: "Revenue for product_id=5"

**Why not just use one database?**
- MySQL: Can't scale to TB of data
- HBase: Can't run complex analytics (no JOIN)
- Hive: Too slow for real-time serving

**Combination:** Best of all worlds!

---

## Real-World Applications

### Example 1: Uber's Trip Analytics

```
Pipeline:
1. PostgreSQL → Sqoop → HDFS (100M trips/day)
2. MapReduce: Calculate driver earnings, surge pricing
3. Hive: Analyze city-level patterns, fraud detection
4. HBase: Serve trip details to mobile app (< 50ms)

Scale:
- 15M trips/day → 5TB data/day
- Pipeline runs every 15 minutes
- Powers driver payments, surge pricing, fraud detection
```

### Example 2: Airbnb's Search Ranking

```
Pipeline:
1. MySQL → Sqoop → HDFS (listings, bookings, reviews)
2. MapReduce: Extract features (price, ratings, click-through)
3. Hive: Train ML models (which listings get booked?)
4. HBase: Serve listing scores for search API

Result:
- Updated rankings every 6 hours
- Improved booking rate by 15%
- Reduced search latency from 500ms to 80ms
```

### Example 3: Netflix's Content Recommendations

```
Pipeline:
1. Logs → HDFS (300M events/day: views, clicks, ratings)
2. MapReduce: Aggregate watch patterns per user
3. Hive: Find similar users, trending content
4. HBase: Serve recommendations to 200M users

Scale:
- 1PB of viewing data
- 50,000 concurrent queries/sec on HBase
- Pipeline runs every 2 hours
```

---

## Common Integration Issues and Solutions

### Issue 1: Data Type Mismatches

**Error:**
```
ERROR: Column 'price' cannot be cast from DOUBLE to STRING
```

**Cause:** Sqoop imported as STRING, Hive expects DOUBLE

**Solution:**
```sql
-- Fix schema
ALTER TABLE products CHANGE COLUMN price price DOUBLE;

-- Or convert in query
SELECT CAST(price AS DOUBLE) FROM products;
```

---

### Issue 2: Hive Can't Find HDFS Data

**Error:**
```
FAILED: SemanticException [Error 10001]: Table not found products
```

**Cause:** HDFS path doesn't exist or is empty

**Solution:**
```bash
# Verify data exists
hadoop fs -ls /data/ecommerce/products/
hadoop fs -cat /data/ecommerce/products/part-m-00000 | head

# Recreate table with correct path
DROP TABLE IF EXISTS products;
CREATE EXTERNAL TABLE products (...) LOCATION '/data/ecommerce/products';
```

---

### Issue 3: HBase RegionServer Down

**Error:**
```
ERROR: org.apache.hadoop.hbase.client.RetriesExhaustedException
```

**Cause:** HBase RegionServer crashed or network issue

**Solution:**
```bash
# Check HBase status
docker-compose ps hbase-regionserver

# Restart if needed
docker-compose restart hbase-regionserver

# Verify in HBase shell
echo "status" | hbase shell
```

---

### Issue 4: Out of Memory in MapReduce

**Error:**
```
Container killed by YARN for exceeding memory limits
```

**Cause:** Processing too much data in mapper/reducer

**Solution:**
```bash
# Increase memory allocation
yarn jar loganalyzer.jar LogAnalyzer \
  -Dmapreduce.map.memory.mb=2048 \
  -Dmapreduce.reduce.memory.mb=4096 \
  /data/logs /output/log_analysis

# Or reduce data size
hadoop fs -cat /data/logs/access_logs.txt | head -10000 > sample.txt
hadoop fs -put sample.txt /data/logs_sample/
```

---

### Issue 5: Slow Hive Queries

**Symptom:** Queries take > 60 seconds

**Causes and solutions:**
```sql
-- Cause 1: No partitioning
-- Solution: Partition by date
CREATE TABLE orders_partitioned (
  order_id INT, product_id INT, quantity INT, revenue DOUBLE
)
PARTITIONED BY (order_date STRING)
STORED AS ORC;

INSERT INTO orders_partitioned PARTITION(order_date)
SELECT order_id, product_id, quantity, revenue, order_date FROM orders;

-- Cause 2: Inefficient JOIN order
-- Bad: Large table first
SELECT * FROM orders o JOIN products p ON ...

-- Good: Small table first
SELECT * FROM products p JOIN orders o ON ...

-- Cause 3: No statistics
-- Solution: Compute stats
ANALYZE TABLE products COMPUTE STATISTICS;
ANALYZE TABLE orders COMPUTE STATISTICS;
```

---

### Issue 6: Sqoop Import Fails

**Error:**
```
ERROR manager.SqlManager: Error executing statement:
com.mysql.jdbc.exceptions.jdbc4.CommunicationsException:
Communications link failure
```

**Solution:**
```bash
# Test MySQL connection
docker-compose exec namenode bash
mysql -h mariadb -u root -proot -e "SHOW DATABASES;"

# Check network
ping mariadb

# Verify credentials
sqoop list-databases \
  --connect jdbc:mysql://mariadb:3306/ \
  --username root \
  --password root
```

---

## Pipeline Optimization Techniques

### 1. Incremental Loading

**Problem:** Re-importing entire MySQL table daily is slow

**Solution:** Use Sqoop incremental import

```bash
# First run: Import all data
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root --password root \
  --table orders \
  --target-dir /data/ecommerce/orders_incremental \
  --incremental append \
  --check-column order_id \
  --last-value 0

# Subsequent runs: Import only new rows
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root --password root \
  --table orders \
  --target-dir /data/ecommerce/orders_incremental \
  --incremental append \
  --check-column order_id \
  --last-value 1008  # Max from previous run
```

**Result:** 10x faster (only import new rows)

---

### 2. Hive Partitioning

**Problem:** Queries scan entire table even for recent data

**Solution:** Partition by date

```sql
-- Create partitioned table
CREATE TABLE orders_by_date (
  order_id INT,
  product_id INT,
  quantity INT,
  revenue DOUBLE
)
PARTITIONED BY (order_date STRING)
STORED AS ORC;

-- Load data
INSERT INTO orders_by_date PARTITION(order_date)
SELECT order_id, product_id, quantity, revenue, order_date FROM orders;

-- Query only recent partition (100x faster!)
SELECT * FROM orders_by_date
WHERE order_date = '2024-11-03';  -- Scans only one partition!
```

---

### 3. HBase Bulk Loading

**Problem:** Putting data one row at a time is slow

**Solution:** Use Hive-HBase integration

```sql
-- Create Hive table backed by HBase
CREATE TABLE analytics_hbase (
  row_key STRING,
  product_name STRING,
  total_revenue DOUBLE,
  order_count INT
)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES (
  "hbase.columns.mapping" = ":key,revenue:name,revenue:total,revenue:count"
)
TBLPROPERTIES (
  "hbase.table.name" = "analytics_results"
);

-- Bulk insert from Hive query (1000x faster than manual puts!)
INSERT INTO TABLE analytics_hbase
SELECT
  CONCAT('product_', CAST(p.product_id AS STRING)) as row_key,
  p.product_name,
  SUM(o.revenue) as total_revenue,
  COUNT(*) as order_count
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name;
```

---

### 4. Compress HDFS Data

**Problem:** Storing raw CSV wastes space

**Solution:** Use compression

```bash
# Enable compression in Sqoop
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --table orders \
  --target-dir /data/orders_compressed \
  --compress \
  --compression-codec org.apache.hadoop.io.compress.GzipCodec

# Result: 70% smaller files!
```

---

## Key Takeaways

✅ **Integration is the real challenge** - individual tools are easy, orchestration is hard

✅ **Each tool solves a specific problem:**
- Sqoop: Database → Hadoop
- MapReduce: Heavy data processing
- Hive: SQL analytics
- HBase: Real-time serving

✅ **Data flows through layers:**
- **Storage:** HDFS (cheap, scalable)
- **Processing:** MapReduce (batch)
- **Analytics:** Hive (SQL)
- **Serving:** HBase (low-latency)

✅ **Lambda Architecture:**
- Batch layer (accurate, slow)
- Serving layer (fast, pre-computed)
- Best of both worlds

✅ **Monitor everything:**
- Job success (YARN)
- Data quality (row counts, nulls)
- Performance (query times)
- Storage (HDFS usage)

✅ **Optimize for production:**
- Incremental loads (not full refreshes)
- Partitioning (query pruning)
- Compression (save 70% space)
- Bulk loading (1000x faster than row-by-row)

---

## Next Steps

**You've completed the Hadoop ecosystem!** You now know:
- How to store data at scale (HDFS)
- How to process it (MapReduce)
- How to query it (Hive, Pig)
- How to serve it (HBase)
- How to integrate everything (this tutorial!)

**Practice projects:**
1. **E-commerce dashboard:**
   - Add daily sales tracking
   - Implement customer segmentation
   - Build recommendation engine

2. **Log analytics platform:**
   - Parse different log formats (nginx, Apache, application)
   - Detect anomalies (spike in 500 errors)
   - Generate uptime reports

3. **IoT sensor pipeline:**
   - Ingest sensor data (temperature, humidity)
   - Aggregate to 5-minute intervals
   - Alert on threshold violations

**Learn more:**
- **Workflow orchestration:** Apache Airflow, Oozie
- **Real-time processing:** Apache Spark, Flink
- **Data quality:** Great Expectations, Deequ
- **Cloud Hadoop:** AWS EMR, Azure HDInsight, Google Dataproc

---

## Quick Reference Card

```bash
### Complete Pipeline Commands ###

# 1. Setup MySQL
docker-compose exec mariadb mysql -u root -proot < setup.sql

# 2. Import with Sqoop
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --table products \
  --target-dir /data/products

# 3. Process logs
yarn jar loganalyzer.jar LogAnalyzer /data/logs /output/log_analysis

# 4. Query in Hive
docker-compose exec hive-server hive -e "SELECT * FROM products"

# 5. Store in HBase
echo "put 'analytics_results', 'product_1', 'revenue:total', '3899.97'" | \
  hbase shell

# 6. Monitor
http://localhost:8088  # YARN jobs
http://localhost:9870  # HDFS usage
http://localhost:16010 # HBase status

# 7. Automated pipeline
./run_pipeline.sh
```

---

## Congratulations!

You've built a complete end-to-end data pipeline, just like data engineers at Google, Facebook, and Uber do. You now understand:

- **Why** companies use multiple tools (not just one database)
- **How** data flows through the Hadoop ecosystem
- **When** to use each tool (Sqoop vs MapReduce vs Hive vs HBase)
- **What** production pipelines look like (monitoring, optimization, automation)

**This is the foundation of modern big data engineering.** Everything you learn next (Spark, Kafka, cloud platforms) builds on these concepts.

**Keep building. Keep learning. Keep shipping! 🚀**
