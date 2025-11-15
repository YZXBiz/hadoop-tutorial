# Tutorial 02: MapReduce WordCount

**Duration:** 45-60 minutes
**Difficulty:** Beginner
**Prerequisites:** Complete Tutorial 01 (HDFS Basics)

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What MapReduce is** and why it's revolutionary for big data
- **How parallel processing works** across multiple machines
- **The Map → Shuffle → Reduce flow** with real examples
- **How to run and monitor** MapReduce jobs
- **When to use MapReduce** vs other processing frameworks

**Real-world relevance:** MapReduce was the foundation of Google's web indexing. Companies like Facebook, Twitter, and LinkedIn use MapReduce-style processing to analyze billions of events daily.

---

## Conceptual Overview: What is MapReduce?

### The Problem: Processing Massive Data

**Scenario:** You have 1TB of server logs and need to count how many times each error code appears.

**Traditional approach (single machine):**
```
Read 1TB → Process sequentially → Could take 10+ hours
Problem: Slow, single point of failure, limited by one machine's CPU/memory
```

**MapReduce approach (distributed):**
```
Split 1TB into 1000 pieces → Process in parallel on 100 machines → Done in 10 minutes
Each machine processes 10GB independently, then results combine
```

---

### The MapReduce Mental Model

Think of MapReduce like counting votes in an election:

```
Step 1: MAP (Distribute the work)
  Poll 1: Count votes → Alice: 50, Bob: 30
  Poll 2: Count votes → Alice: 40, Bob: 60
  Poll 3: Count votes → Alice: 70, Bob: 20

Step 2: SHUFFLE (Group by candidate)
  Alice votes: [50, 40, 70]
  Bob votes:   [30, 60, 20]

Step 3: REDUCE (Sum up results)
  Alice: 50 + 40 + 70 = 160 total
  Bob:   30 + 60 + 20 = 110 total
```

Replace "candidates" with "words" and you have WordCount!

---

### MapReduce Architecture

```
                  ┌─────────────────────────────┐
                  │     YARN ResourceManager    │
                  │  (Schedules jobs on cluster)│
                  └──────────┬──────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │ Node 1  │         │ Node 2  │         │ Node 3  │
   ├─────────┤         ├─────────┤         ├─────────┤
   │ Mapper  │         │ Mapper  │         │ Mapper  │
   │ reads   │         │ reads   │         │ reads   │
   │ Block 1 │         │ Block 2 │         │ Block 3 │
   └────┬────┘         └────┬────┘         └────┬────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌───────▼────────┐
                    │  SHUFFLE PHASE │
                    │ Group by key   │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌───▼─────┐        ┌───▼─────┐
   │Reducer 1│         │Reducer 2│        │Reducer 3│
   │(a-f)    │         │(g-m)    │        │(n-z)    │
   └────┬────┘         └────┬────┘        └────┬────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                     ┌──────▼───────┐
                     │ Final Output │
                     │   in HDFS    │
                     └──────────────┘
```

---

### The Three Phases Explained

#### Phase 1: MAP
**What it does:** Transforms input data into key-value pairs

**Example with text:**
```
Input line: "the cat sat on the mat"

Mapper output:
  (the, 1)
  (cat, 1)
  (sat, 1)
  (on, 1)
  (the, 1)
  (mat, 1)
```

**Key insight:** Each word becomes a key, value is always 1 (one occurrence)

#### Phase 2: SHUFFLE & SORT
**What it does:** Hadoop automatically groups all values for the same key

**Example:**
```
Mapper 1 output:  (the, 1), (cat, 1), (the, 1)
Mapper 2 output:  (the, 1), (dog, 1), (cat, 1)

After Shuffle:
  the → [1, 1, 1]  (from 3 different mappers)
  cat → [1, 1]     (from 2 different mappers)
  dog → [1]        (from 1 mapper)
```

**Key insight:** This happens automatically - you don't write code for it!

#### Phase 3: REDUCE
**What it does:** Aggregates all values for each key

**Example:**
```
Input to Reducer:
  key="the", values=[1, 1, 1]

Reducer logic:
  sum = 0
  for each value in [1, 1, 1]:
    sum += value

Output:
  (the, 3)
```

**Key insight:** Reducer receives ALL occurrences of a key

---

## WordCount: A Complete Walkthrough

Let's trace what happens when we count words in: **"to be or not to be"**

### Input File (in HDFS)
```
to be or not to be
```

### Step 1: Input Split
Hadoop splits input into lines for mappers:
```
Mapper 1 gets: "to be or not to be"
```

### Step 2: Map Phase
```java
// Mapper receives: "to be or not to be"
// Tokenizes into words and emits (word, 1) for each

Output:
  (to, 1)
  (be, 1)
  (or, 1)
  (not, 1)
  (to, 1)    ← Second occurrence
  (be, 1)    ← Second occurrence
```

### Step 3: Shuffle & Sort
```
Hadoop groups by key automatically:
  be  → [1, 1]
  not → [1]
  or  → [1]
  to  → [1, 1]
```

### Step 4: Reduce Phase
```java
// Reducer for key "be" receives: [1, 1]
sum = 1 + 1 = 2
emit (be, 2)

// Reducer for key "to" receives: [1, 1]
sum = 1 + 1 = 2
emit (to, 2)

// Reducer for key "or" receives: [1]
sum = 1
emit (or, 1)

// Reducer for key "not" receives: [1]
sum = 1
emit (not, 1)
```

### Final Output (in HDFS)
```
be	2
not	1
or	1
to	2
```

---

## Hands-On: Running WordCount

### Exercise 1: Prepare Input Data

**Step 1: Connect to NameNode**
```bash
docker-compose exec namenode bash
```

**Step 2: Create HDFS directories**
```bash
# Input directory
hadoop fs -mkdir -p /input

# Verify
hadoop fs -ls /
```

**Expected output:**
```
Found 3 items
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 11:00 /input
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 10:00 /tmp
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 10:00 /user
```

**Step 3: Upload Shakespeare text**
```bash
# Upload the data file
hadoop fs -put /datasets/wordcount/shakespeare.txt /input/

# Verify upload
hadoop fs -ls /input/
```

**Expected output:**
```
Found 1 items
-rw-r--r--   2 hadoop supergroup    5458199 2025-11-15 11:05 /input/shakespeare.txt
```

**What we just did:**
- Created `/input` directory in HDFS (not local filesystem)
- Uploaded ~5.2MB of Shakespeare's works
- This file contains ~800,000 words across 124,000 lines

**Preview the data:**
```bash
hadoop fs -cat /input/shakespeare.txt | head -20
```

---

### Exercise 2: Run WordCount Job

**Step 1: Locate the example JAR**
```bash
# Find the Hadoop examples JAR
ls -lh /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar
```

**Expected output:**
```
-rw-r--r-- 1 hadoop hadoop 301K hadoop-mapreduce-examples-3.3.6.jar
```

**What this JAR contains:** Pre-built MapReduce programs including WordCount

**Step 2: Run the job**
```bash
yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  wordcount \
  /input/shakespeare.txt \
  /output/wordcount
```

**Command breakdown:**
- `yarn jar` = Submit a JAR file to YARN for execution
- `hadoop-mapreduce-examples-3.3.6.jar` = The JAR file
- `wordcount` = Which program inside the JAR to run
- `/input/shakespeare.txt` = Input path in HDFS
- `/output/wordcount` = Output path in HDFS (must not exist!)

**What you'll see (live output):**
```
2025-11-15 11:10:15,482 INFO client.DefaultNoHARMResourceCalculator: Using ResourceCalculator: org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator
2025-11-15 11:10:15,593 INFO mapreduce.JobResourceUploader: Disabling Erasure Coding
2025-11-15 11:10:15,738 INFO input.FileInputFormat: Total input files to process : 1
2025-11-15 11:10:15,893 INFO mapreduce.JobSubmitter: number of splits:1
2025-11-15 11:10:16,125 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1700055015893_0001
...
2025-11-15 11:10:17,234 INFO mapreduce.Job: Running job: job_1700055015893_0001
2025-11-15 11:10:28,456 INFO mapreduce.Job: map 0% reduce 0%
2025-11-15 11:10:35,623 INFO mapreduce.Job: map 100% reduce 0%
2025-11-15 11:10:42,789 INFO mapreduce.Job: map 100% reduce 100%
2025-11-15 11:10:43,801 INFO mapreduce.Job: Job job_1700055015893_0001 completed successfully
...
Counters: 54
  File System Counters
    FILE: Number of bytes read=4523687
    FILE: Number of bytes written=9047374
    HDFS: Number of bytes read=5458199
    HDFS: Number of bytes written=865433
  Map-Reduce Framework
    Map input records=124456
    Map output records=901325
    Reduce input records=67779
    Reduce output records=67779
```

**What just happened (step by step):**

1. **Job Submission (0:00-0:02)**
   - YARN ResourceManager accepts the job
   - Calculates how many mappers needed (based on input size)
   - Creates 1 map task (file is small, < 128MB)

2. **Map Phase (0:02-0:10)**
   - NodeManager starts mapper container
   - Mapper reads shakespeare.txt line by line
   - Outputs (word, 1) for every word
   - Progress shows: `map 100%`

3. **Shuffle Phase (0:10-0:15)**
   - Hadoop sorts and groups mapper output by key
   - Transfers data to reducer
   - Happens automatically behind the scenes

4. **Reduce Phase (0:15-0:18)**
   - Reducer sums counts for each word
   - Writes final output to HDFS
   - Progress shows: `reduce 100%`

5. **Completion (0:18)**
   - Job marked successful
   - Counters display statistics

**Key counters explained:**
- `Map input records=124456` → 124,456 lines processed
- `Map output records=901325` → 901,325 words found (including duplicates)
- `Reduce output records=67779` → 67,779 unique words in Shakespeare's works

---

### Exercise 3: View Results

**Step 1: Check output directory**
```bash
hadoop fs -ls /output/wordcount/
```

**Expected output:**
```
Found 2 items
-rw-r--r--   2 hadoop supergroup          0 2025-11-15 11:10 /output/wordcount/_SUCCESS
-rw-r--r--   2 hadoop supergroup     865433 2025-11-15 11:10 /output/wordcount/part-r-00000
```

**What these files mean:**
- `_SUCCESS` = Empty file indicating job completed successfully
- `part-r-00000` = Output from Reducer 0 (we used 1 reducer)

**Step 2: View the results**
```bash
# View first 20 results
hadoop fs -cat /output/wordcount/part-r-00000 | head -20
```

**Expected output:**
```
&	84
&c	20
''	25
'Affection	1
'All	1
'And	2
'Brutus'	1
'Cassius'	1
'Gainst	2
'Tis	391
'Twas	5
'a	2
'em	25
'fore	3
'gainst	24
'gin	4
'las	1
'midst	2
'mongst	2
'scape	1
```

**Output format:**
```
word    count
```
(Tab-separated values)

**Step 3: Find most common words**
```bash
# Sort by count (descending) and show top 10
hadoop fs -cat /output/wordcount/part-r-00000 | sort -t$'\t' -k2 -nr | head -10
```

**Expected output:**
```
the	27361
and	26028
I	20681
to	19150
of	17463
a	14593
my	12480
in	10956
you	10681
is	9134
```

**Insights:**
- "the" appears 27,361 times (most common)
- These are mostly articles/pronouns (called "stop words")
- Real-world: You'd filter these out for meaningful analysis

---

### Exercise 4: Monitor Job via Web UI

**Open ResourceManager UI:**
```
http://localhost:8088
```

**What you'll see:**

```
┌────────────────────────────────────────────────┐
│        YARN ResourceManager                    │
├────────────────────────────────────────────────┤
│ Cluster Metrics:                               │
│   Active Nodes: 1                              │
│   Memory Used: 2 GB / 8 GB                    │
│   VCores Used: 2 / 8                          │
│                                                │
│ Applications:                                  │
│ ┌────────────────────────────────────────────┐│
│ │ ID: application_1700055015893_0001        ││
│ │ Name: word count                          ││
│ │ State: FINISHED                           ││
│ │ Final Status: SUCCEEDED                   ││
│ │ Progress: 100%                            ││
│ │ Duration: 26 seconds                      ││
│ └────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘
```

**Click on the Application ID to see:**
- Map and Reduce task details
- Resource usage over time
- Logs from each container
- Counters and statistics

---

## Understanding the Java Code

Here's the WordCount code with line-by-line explanations:

### The Mapper Class

```java
public static class TokenizerMapper
     extends Mapper<Object, Text, Text, IntWritable> {

  private final static IntWritable one = new IntWritable(1);
  private Text word = new Text();

  public void map(Object key, Text value, Context context)
      throws IOException, InterruptedException {
    StringTokenizer itr = new StringTokenizer(value.toString());
    while (itr.hasMoreTokens()) {
      word.set(itr.nextToken());
      context.write(word, one);
    }
  }
}
```

**Line-by-line explanation:**

```java
extends Mapper<Object, Text, Text, IntWritable>
         ↑      ↑      ↑     ↑     ↑
         |      |      |     |     └─ Output value type (count: 1)
         |      |      |     └─────── Output key type (word)
         |      |      └───────────── Input value type (line of text)
         |      └──────────────────── Input key type (line number, unused)
         └─────────────────────────── Parent class
```

```java
private final static IntWritable one = new IntWritable(1);
```
**Why?** Create once, reuse for efficiency (instead of `new IntWritable(1)` million times)

```java
StringTokenizer itr = new StringTokenizer(value.toString());
```
**What it does:** Splits "the cat sat" into ["the", "cat", "sat"]

```java
while (itr.hasMoreTokens()) {
  word.set(itr.nextToken());      // Get next word
  context.write(word, one);       // Emit (word, 1)
}
```
**Example:** Input "hello world"
1. First iteration: emit ("hello", 1)
2. Second iteration: emit ("world", 1)

---

### The Reducer Class

```java
public static class IntSumReducer
     extends Reducer<Text, IntWritable, Text, IntWritable> {

  private IntWritable result = new IntWritable();

  public void reduce(Text key, Iterable<IntWritable> values,
                     Context context)
      throws IOException, InterruptedException {
    int sum = 0;
    for (IntWritable val : values) {
      sum += val.get();
    }
    result.set(sum);
    context.write(key, result);
  }
}
```

**Line-by-line explanation:**

```java
extends Reducer<Text, IntWritable, Text, IntWritable>
         ↑      ↑     ↑            ↑     ↑
         |      |     |            |     └─ Output value (total count)
         |      |     |            └─────── Output key (word)
         |      |     └──────────────────── Input value (list of 1s)
         |      └────────────────────────── Input key (word)
         └───────────────────────────────── Parent class
```

```java
Iterable<IntWritable> values
```
**What this is:** Iterator over [1, 1, 1, 1, ...] for all occurrences of a word

**Example:** If "the" appeared 5 times:
```java
key = "the"
values = [1, 1, 1, 1, 1]

Loop:
  sum = 0
  sum += 1  → sum = 1
  sum += 1  → sum = 2
  sum += 1  → sum = 3
  sum += 1  → sum = 4
  sum += 1  → sum = 5

Output: ("the", 5)
```

---

### The Main Method

```java
public static void main(String[] args) throws Exception {
  Configuration conf = new Configuration();
  Job job = Job.getInstance(conf, "word count");

  job.setJarByClass(WordCount.class);
  job.setMapperClass(TokenizerMapper.class);
  job.setCombinerClass(IntSumReducer.class);  // ← Optimization!
  job.setReducerClass(IntSumReducer.class);

  job.setOutputKeyClass(Text.class);
  job.setOutputValueClass(IntWritable.class);

  FileInputFormat.addInputPath(job, new Path(args[0]));
  FileOutputFormat.setOutputPath(job, new Path(args[1]));

  System.exit(job.waitForCompletion(true) ? 0 : 1);
}
```

**Key configuration:**

```java
job.setCombinerClass(IntSumReducer.class);
```

**What's a Combiner?** A "mini-reducer" that runs on mapper output BEFORE shuffle

**Why it helps:**
```
Without Combiner:
  Mapper outputs: (the,1), (the,1), (the,1), (the,1), (the,1)
  Network transfer: 5 records
  Reducer receives: [1,1,1,1,1]

With Combiner:
  Mapper outputs: (the,1), (the,1), (the,1), (the,1), (the,1)
  Combiner runs: (the,5)  ← Reduced locally!
  Network transfer: 1 record (80% less data!)
  Reducer receives: [5] or [2,3] (depending on combiners)
```

**Benefit:** Reduces network traffic and speeds up job

---

## Performance Tuning

### Adjusting Number of Reducers

```bash
# Default: 1 reducer
yarn jar ... wordcount /input /output

# Use 4 reducers (faster for large datasets)
yarn jar ... wordcount \
  -Dmapreduce.job.reduces=4 \
  /input /output
```

**What changes:**
```
1 Reducer:
  - Output: part-r-00000 (all words)

4 Reducers:
  - Output: part-r-00000 (words a-g)
  - Output: part-r-00001 (words h-n)
  - Output: part-r-00002 (words o-t)
  - Output: part-r-00003 (words u-z)
```

**When to use multiple reducers:**
- Large output (> 1GB)
- Want faster processing
- Have multiple CPU cores available

---

### Memory Configuration

```bash
yarn jar ... wordcount \
  -Dmapreduce.map.memory.mb=2048 \
  -Dmapreduce.reduce.memory.mb=4096 \
  -Dmapreduce.map.java.opts="-Xmx1600m" \
  -Dmapreduce.reduce.java.opts="-Xmx3200m" \
  /input /output
```

**What these mean:**
- `map.memory.mb=2048` → Container gets 2GB RAM
- `map.java.opts=-Xmx1600m` → JVM heap is 1.6GB (leave headroom)
- Same logic for reducers

**When to increase:** Processing large records, complex logic, OutOfMemoryError

---

## Common Issues

### Issue 1: Output directory already exists

**Error:**
```
org.apache.hadoop.mapred.FileAlreadyExistsException: Output directory hdfs://namenode:9000/output/wordcount already exists
```

**Solution:**
```bash
# Delete old output
hadoop fs -rm -r /output/wordcount

# Then re-run job
yarn jar ... wordcount /input /output
```

**Why:** Hadoop prevents accidental overwrite of results

---

### Issue 2: Job stuck at 0%

**Symptom:**
```
map 0% reduce 0%
(stays this way for minutes)
```

**Solutions:**
```bash
# Check if NodeManager is running
docker-compose ps nodemanager

# Check ResourceManager logs
docker-compose logs resourcemanager

# Verify HDFS is healthy
hadoop fs -ls /
```

---

### Issue 3: Job fails with "Container killed"

**Error in logs:**
```
Container killed on request. Exit code is 143
Container killed by YARN for exceeding memory limits
```

**Solution:**
```bash
# Increase memory limits
yarn jar ... wordcount \
  -Dmapreduce.map.memory.mb=4096 \
  -Dmapreduce.reduce.memory.mb=8192 \
  /input /output
```

---

## Exercises

### Exercise 1: Count Words in Different Text

```bash
# Try with access logs
hadoop fs -put /datasets/logs/access_logs.txt /input/logs.txt
yarn jar ... wordcount /input/logs.txt /output/logs-count
hadoop fs -cat /output/logs-count/part-r-00000 | head
```

**Question:** What are the most common HTTP status codes?

---

### Exercise 2: Find Rare Words

```bash
# Words that appear only once
hadoop fs -cat /output/wordcount/part-r-00000 | \
  awk -F'\t' '$2 == 1' | \
  head -20
```

**Expected:** Names, places, rare terms

---

### Exercise 3: Analyze Results

```bash
# Total unique words
hadoop fs -cat /output/wordcount/part-r-00000 | wc -l

# Total word occurrences
hadoop fs -cat /output/wordcount/part-r-00000 | \
  awk -F'\t' '{sum += $2} END {print sum}'

# Average word frequency
hadoop fs -cat /output/wordcount/part-r-00000 | \
  awk -F'\t' '{sum += $2; count++} END {print sum/count}'
```

---

## Real-World Applications

### Application 1: Log Analysis
```
Input: 1TB of web server logs
Map: Extract (status_code, 1)
Reduce: Count each status code
Output: 200: 10M requests, 404: 50K, 500: 1K
```

### Application 2: Click Analytics
```
Input: User clickstream data
Map: Extract (product_id, 1)
Reduce: Count clicks per product
Output: Top products by engagement
```

### Application 3: Data Quality Check
```
Input: Customer records
Map: Extract (email_domain, 1)
Reduce: Count records per domain
Output: Detect patterns, find spam domains
```

---

## Key Takeaways

✅ **MapReduce processes data in parallel** across multiple machines

✅ **Map phase transforms** input into key-value pairs

✅ **Shuffle phase groups** all values for each key automatically

✅ **Reduce phase aggregates** values to produce final results

✅ **WordCount is the "Hello World"** of big data - simple but powerful pattern

✅ **Same pattern applies** to many problems: counting, summing, averaging, grouping

---

## When to Use MapReduce

### ✓ Good fit:
- Batch processing of large datasets (TB+)
- Aggregations, counting, grouping
- ETL (Extract, Transform, Load)
- Log analysis
- Data transformation

### ✗ Not ideal for:
- Real-time processing (use Spark Streaming instead)
- Iterative algorithms (use Spark for machine learning)
- Small datasets (< 1GB) - overhead not worth it
- Complex joins (use Hive SQL instead)

---

## Next Steps

**You've mastered MapReduce fundamentals!** Now you can:

1. **Move to Tutorial 03** to learn Hive (SQL on top of MapReduce)
2. **Write custom MapReduce:**
   - Try implementing word length average
   - Count lines per file
   - Find max/min values
3. **Read more:** [MapReduce paper by Google](https://research.google/pubs/pub62/)

---

## Quick Reference

```bash
# Run WordCount
yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  wordcount /input /output

# Monitor job
http://localhost:8088

# View results
hadoop fs -cat /output/part-r-00000 | head

# Clean up
hadoop fs -rm -r /output

# Job history
http://localhost:19888
```

**Remember:** Output directory must not exist before running!
