# Tutorial 08: Integration Project - End-to-End Data Pipeline

Complete a real-world data pipeline combining multiple Hadoop ecosystem tools.

## Project Overview

Build an e-commerce analytics pipeline that:
1. Imports product and order data from MySQL
2. Processes large log files with MapReduce
3. Performs SQL analytics with Hive
4. Stores results in HBase
5. Generates actionable insights

## Learning Objectives

- Integrate multiple Hadoop tools in a single workflow
- Build ETL pipelines
- Process heterogeneous data
- Implement data quality checks
- Monitor and optimize the pipeline

## Project Architecture

```
MySQL DB → Sqoop → HDFS
         ↓
     HDFS ← MapReduce (Log Processing)
         ↓
     HDFS → Hive (Analytics SQL)
         ↓
    HBase (NoSQL Results)
         ↓
   Reports & Dashboards
```

## Step 1: Prepare Source Data

### Setup MySQL Database

```bash
docker-compose exec mariadb mysql -u root -proot

# Create e-commerce database
CREATE DATABASE ecommerce;
USE ecommerce;

# Create tables
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(10, 2),
  stock INT
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  product_id INT,
  quantity INT,
  order_date DATE,
  revenue DECIMAL(10, 2),
  FOREIGN KEY(product_id) REFERENCES products(product_id)
);

# Insert sample data
INSERT INTO products VALUES
  (1, 'Laptop Pro', 'Electronics', 1299.99, 50),
  (2, 'Wireless Mouse', 'Electronics', 29.99, 200),
  (3, 'USB Cable', 'Electronics', 12.99, 500),
  (4, 'Office Chair', 'Furniture', 299.99, 30);

INSERT INTO orders VALUES
  (1001, 1, 2, '2024-11-01', 2599.98),
  (1002, 2, 5, '2024-11-01', 149.95),
  (1003, 3, 10, '2024-11-01', 129.90),
  (1004, 1, 1, '2024-11-02', 1299.99),
  (1005, 4, 3, '2024-11-02', 899.97);

EXIT;
```

### Verify Sample Log Data

```bash
# Check available sample data
ls -la /datasets/logs/
ls -la /datasets/structured/
```

## Step 2: Import Data with Sqoop

```bash
docker-compose exec namenode bash

# Import products table
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table products \
  --target-dir /data/products \
  --delete-target-dir \
  --num-mappers 1

# Import orders table
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table orders \
  --target-dir /data/orders \
  --delete-target-dir \
  --num-mappers 1

# Verify imports
hadoop fs -cat /data/products/part-m-00000
hadoop fs -cat /data/orders/part-m-00000
```

## Step 3: Process Logs with MapReduce

### Copy log data to HDFS

```bash
hadoop fs -mkdir -p /data/logs
hadoop fs -put /datasets/logs/access_logs.txt /data/logs/
```

### Create MapReduce job to analyze logs

```java
// SaveLogAnalyzer.java
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

public class LogAnalyzer {
  public static class LogMapper extends Mapper<Object, Text, Text, IntWritable> {
    private Text statusCode = new Text();
    private IntWritable one = new IntWritable(1);

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {
      String[] fields = value.toString().split(" ");
      if (fields.length >= 9) {
        statusCode.set(fields[8]);
        context.write(statusCode, one);
      }
    }
  }

  public static class LogReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
    public void reduce(Text key, Iterable<IntWritable> values, Context context)
        throws IOException, InterruptedException {
      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      context.write(key, new IntWritable(sum));
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
```

### Compile and run

```bash
# Compile
javac -cp /opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/* \
  LogAnalyzer.java

# Create JAR
jar cvf loganalyzer.jar LogAnalyzer*.class

# Run job
yarn jar loganalyzer.jar LogAnalyzer /data/logs /output/log_analysis

# View results
hadoop fs -cat /output/log_analysis/part-r-00000
```

## Step 4: Analytics with Hive

### Create Hive tables

```bash
docker-compose exec hive-server hive
```

```hql
-- Create products table from Sqoop import
CREATE EXTERNAL TABLE products (
  product_id INT,
  product_name STRING,
  category STRING,
  price DOUBLE,
  stock INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/data/products';

-- Create orders table
CREATE EXTERNAL TABLE orders (
  order_id INT,
  product_id INT,
  quantity INT,
  order_date STRING,
  revenue DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/data/orders';

-- Create log analysis results table
CREATE EXTERNAL TABLE log_stats (
  status_code STRING,
  count INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/output/log_analysis';
```

### Run analytics queries

```hql
-- Total revenue by product
SELECT
  p.product_name,
  SUM(o.revenue) as total_revenue,
  SUM(o.quantity) as total_quantity
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Revenue by category
SELECT
  p.category,
  SUM(o.revenue) as total_revenue,
  COUNT(*) as order_count,
  AVG(o.revenue) as avg_order_value
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.category;

-- Top performing products
SELECT
  p.product_name,
  o.order_date,
  o.revenue
FROM products p
JOIN orders o ON p.product_id = o.product_id
WHERE o.revenue > 1000
ORDER BY o.revenue DESC;
```

## Step 5: Store Results in HBase

```bash
docker-compose exec hbase-master hbase shell
```

```ruby
# Create HBase table
create 'analytics_results', 'revenue', 'logs'

# Store product revenue results
put 'analytics_results', 'product_1', 'revenue:total', '3899.97'
put 'analytics_results', 'product_1', 'revenue:count', '2'
put 'analytics_results', 'product_1', 'revenue:avg', '1949.985'

put 'analytics_results', 'product_2', 'revenue:total', '149.95'
put 'analytics_results', 'product_2', 'revenue:count', '1'
put 'analytics_results', 'product_2', 'revenue:avg', '149.95'

# Store log stats
put 'analytics_results', 'logs_2024_11_15', 'logs:status_200', '15'
put 'analytics_results', 'logs_2024_11_15', 'logs:status_401', '1'
put 'analytics_results', 'logs_2024_11_15', 'logs:status_404', '1'

# Query results
scan 'analytics_results'
```

## Step 6: Generate Reports

```bash
# Create report directory
docker-compose exec namenode bash
hadoop fs -mkdir -p /reports

# Export results
hadoop fs -cat /output/log_analysis/part-r-00000 > report_log_analysis.txt
```

## Complete Pipeline Script

Create `run_pipeline.sh`:

```bash
#!/bin/bash

set -e

echo "========================================="
echo "Starting E-commerce Analytics Pipeline"
echo "========================================="

# Step 1: Import data
echo "[Step 1] Importing data from MySQL..."
sqoop import \
  --connect jdbc:mysql://mariadb:3306/ecommerce \
  --username root \
  --password root \
  --table products \
  --target-dir /data/products \
  --delete-target-dir \
  --num-mappers 1 2>&1 | grep -v "Warning"

# Step 2: Process logs
echo "[Step 2] Processing log files..."
hadoop fs -mkdir -p /data/logs
hadoop fs -put /datasets/logs/access_logs.txt /data/logs/ 2>/dev/null || true

# Compile and run MapReduce
javac -cp /opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/* \
  /tutorials/08-integration-project/LogAnalyzer.java 2>/dev/null

jar cvf /tmp/loganalyzer.jar /tutorials/08-integration-project/LogAnalyzer*.class \
  2>&1 | grep -v "adding"

yarn jar /tmp/loganalyzer.jar LogAnalyzer /data/logs /output/log_analysis 2>&1 | tail -5

# Step 3: Run Hive queries
echo "[Step 3] Running analytics queries..."
hive -f /tutorials/08-integration-project/queries.hql

echo ""
echo "========================================="
echo "Pipeline Complete!"
echo "========================================="
echo ""
echo "Results location:"
echo "  - Log analysis: /output/log_analysis"
echo "  - HBase table: analytics_results"
```

## Project Checklist

- [ ] Setup MySQL database with test data
- [ ] Import data tables with Sqoop
- [ ] Copy log files to HDFS
- [ ] Develop and test MapReduce log analyzer
- [ ] Create Hive tables on imported data
- [ ] Execute analytics queries
- [ ] Store results in HBase
- [ ] Generate final reports
- [ ] Document findings

## Key Learnings

1. **Data Movement**: Sqoop bridges databases and Hadoop
2. **Distributed Processing**: MapReduce processes large datasets
3. **SQL Analytics**: Hive provides familiar SQL interface
4. **NoSQL Storage**: HBase stores results efficiently
5. **Integration**: Combining tools creates powerful pipelines

## Performance Metrics

Monitor your pipeline:
- Data ingestion time
- MapReduce job duration
- Query execution time
- Storage utilization
- Network I/O

## Troubleshooting Checklist

- [ ] MySQL connection working
- [ ] HDFS has sufficient space
- [ ] HBase cluster healthy
- [ ] File permissions correct
- [ ] Java classpath configured
- [ ] Input data formats correct

## Extension Ideas

1. Add real-time streaming with Kafka
2. Implement machine learning with Spark
3. Create dashboards with visualization tools
4. Add data quality checks
5. Implement incremental processing
6. Add data compression and optimization

## Summary

This project demonstrates:
- How to build end-to-end data pipelines
- Integration of multiple Hadoop ecosystem components
- Best practices in distributed data processing
- Real-world data scenarios and challenges
