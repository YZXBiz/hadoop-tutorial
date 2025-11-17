# Tutorial 07: Advanced MapReduce

**Duration:** 60-75 minutes
**Difficulty:** Advanced

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **MapReduce internals** - what happens between Map and Reduce (Shuffle & Sort)
- **Combiners** - local pre-aggregation to reduce network traffic by 90%+
- **Partitioners** - controlling data distribution across reducers
- **Custom comparators** - defining sort order for complex keys
- **Advanced patterns** - inverted index, log analysis, top-N queries
- **Performance optimization** - making jobs 10x faster

**Real-world relevance:** Understanding MapReduce internals is crucial for writing efficient big data jobs. Companies like Google, Facebook, and Twitter have teams dedicated to optimizing MapReduce performance. A well-optimized job can save millions in infrastructure costs.

---

## Conceptual Overview: MapReduce Internals

### The Complete MapReduce Flow

In Tutorial 02, we saw the basic Map → Reduce flow. Now let's see what **really** happens:

```
┌────────────────────────────────────────────────────────────────┐
│  PHASE 1: MAP (Distributed Processing)                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Input Split 1 → Mapper 1 → ("apple", 1), ("banana", 1), ...  │
│  Input Split 2 → Mapper 2 → ("apple", 1), ("cherry", 1), ...  │
│  Input Split 3 → Mapper 3 → ("banana", 1), ("apple", 1), ...  │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  PHASE 2: COMBINER (Optional Local Aggregation)               │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Mapper 1 output: ("apple", 1), ("apple", 1), ("apple", 1)    │
│  ↓ Combiner                                                    │
│  ("apple", 3)  ← Reduced from 3 records to 1!                 │
│                                                                │
│  Network transfer: 1 record instead of 3 (67% reduction)       │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  PHASE 3: SHUFFLE (Network Transfer)                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  All "apple" records → Reducer 1                              │
│  All "banana" records → Reducer 2                             │
│  All "cherry" records → Reducer 3                             │
│                                                                │
│  ↓ Partitioner decides which reducer gets which key           │
│  ↓ Data transferred over network (expensive!)                 │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  PHASE 4: SORT (Merge-Sort on Reducer)                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Reducer 1 receives: ("apple", 3), ("apple", 2), ("apple", 1) │
│  ↓ Sort by key (already happens automatically!)               │
│  Sorted: ("apple", [3, 2, 1])  ← Values grouped by key        │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  PHASE 5: REDUCE (Final Aggregation)                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  reduce("apple", [3, 2, 1]) → ("apple", 6)                    │
│  reduce("banana", [5, 3])   → ("banana", 8)                   │
│  reduce("cherry", [2])      → ("cherry", 2)                   │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  OUTPUT (Written to HDFS)                                     │
│  part-r-00000: apple  6                                       │
│  part-r-00001: banana 8                                       │
│  part-r-00002: cherry 2                                       │
└────────────────────────────────────────────────────────────────┘
```

---

### The Shuffle & Sort Phase (The Hidden Bottleneck)

**The shuffle phase is often the slowest part of MapReduce!** Here's why:

```
Map Output (on each mapper node):
┌──────────────────────────────────────┐
│ In-Memory Buffer                     │
│ ("apple", 1)                         │
│ ("banana", 1)                        │
│ ("apple", 1)                         │
│ ("cherry", 1)                        │
│ ...                                  │
│ (Buffer fills up at 80% = 100MB)    │
└──────────────────────────────────────┘
           ↓ Spill to disk
┌──────────────────────────────────────┐
│ Sorted Spill File 1                  │
│ ("apple", 1), ("apple", 1)           │
│ ("banana", 1)                        │
│ ("cherry", 1)                        │
└──────────────────────────────────────┘
           ↓ Partition by key hash
┌──────────────────────────────────────┐
│ Partition 0 → Reducer 0              │
│ Partition 1 → Reducer 1              │
│ Partition 2 → Reducer 2              │
└──────────────────────────────────────┘
           ↓ Network transfer
┌──────────────────────────────────────┐
│ Reducer fetches data from all mappers│
│ 100 mappers × 3 partitions           │
│ = 300 network connections!           │
└──────────────────────────────────────┘
```

**Why this is slow:**
- **Network I/O**: Transferring gigabytes across network
- **Disk I/O**: Spilling to disk when buffer fills
- **Sorting**: Merge-sort of spill files
- **Many small files**: 100 mappers → 100 fetch operations per reducer

**This is where Combiners help!**

---

### Combiner: Local Pre-Aggregation

**Problem:** Without combiner, every (word, 1) pair is sent over network.

```
Mapper 1 output (shakespeare.txt chunk):
  ("the", 1), ("the", 1), ("the", 1), ..., ("the", 1)  ← 50 times
  ("and", 1), ("and", 1), ("and", 1), ..., ("and", 1)  ← 30 times

Without Combiner:
  80 records sent over network → Reducer

With Combiner (local aggregation):
  ("the", 50), ("and", 30) → 2 records sent over network!

Network traffic reduced by 40x!
```

**Visual comparison:**

```
WITHOUT COMBINER:                     WITH COMBINER:
┌────────────┐                        ┌────────────┐
│  Mapper 1  │                        │  Mapper 1  │
│            │                        │            │
│ ("the", 1) │                        │ ("the", 1) │
│ ("the", 1) │                        │ ("the", 1) │
│ ("the", 1) │  ← 100 records         │ ("the", 1) │
│ ...        │                        │ ...        │
└──────┬─────┘                        └──────┬─────┘
       │                                     │
       │ Network: 100 records                │ ↓ Combiner (local)
       │                                     │ ("the", 100)
       ▼                                     ▼
┌────────────┐                        ┌────────────┐
│  Reducer   │                        │  Reducer   │
│            │                        │            │
│ Receives:  │                        │ Receives:  │
│ 100 records│                        │ 1 record   │
└────────────┘                        └────────────┘

Cost: High network/memory              Cost: Low network/memory
```

---

### Partitioner: Controlling Data Distribution

**Default behavior:** Hash partitioning

```java
// Default implementation
partition = (key.hashCode() & Integer.MAX_VALUE) % numReducers

Example with 3 reducers:
  hash("apple")  % 3 = 1 → Reducer 1
  hash("banana") % 3 = 2 → Reducer 2
  hash("cherry") % 3 = 0 → Reducer 0
```

**Problem:** Sometimes you want custom distribution logic.

**Example use case:** Alphabetical partitioning

```
Words starting with A-G → Reducer 0
Words starting with H-N → Reducer 1
Words starting with O-U → Reducer 2
Words starting with V-Z → Reducer 3

Benefits:
  - Output files are alphabetically organized
  - Easy to find words in specific ranges
  - Load balancing based on data characteristics
```

---

### Custom Comparator: Sorting Order

**Default:** Keys sorted in ascending order (lexicographical for Text).

**Custom use cases:**
- **Descending order**: Show highest counts first
- **Numeric sorting**: Treat "10" as greater than "9" (not lexicographical)
- **Complex keys**: Sort by multiple fields (e.g., date then time)

```
Default (ascending):
  apple   5
  banana  10
  cherry  3

Descending (using custom comparator):
  banana  10
  apple   5
  cherry  3

Useful for: Top-N queries, leaderboards, time-series data
```

---

## Prerequisites

Before starting, ensure:
```bash
# Check that your cluster is running
docker-compose ps

# You should see:
# - namenode
# - resourcemanager
# - nodemanager
```

**Java knowledge:**
- Comfortable with Java classes and inheritance
- Understand generics (e.g., `Reducer<K, V, K, V>`)
- Familiar with basic MapReduce from Tutorial 02

---

## Hands-On Exercises

### Exercise 1: Combiner Optimization

**Concept:** Adding a Combiner to reduce network traffic.

**Create the Java file:**

```bash
docker-compose exec namenode bash

# Create working directory
mkdir -p /opt/mapreduce-examples
cd /opt/mapreduce-examples

# Create the Java file
cat > WordCountWithCombiner.java << 'EOF'
import java.io.IOException;
import java.util.StringTokenizer;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCountWithCombiner {

  // MAPPER: Emit (word, 1) for each word
  public static class TokenizerMapper
      extends Mapper<Object, Text, Text, IntWritable> {

    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {

      // Tokenize the line
      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        // Clean the word: remove punctuation, lowercase
        String cleanWord = itr.nextToken()
            .replaceAll("[^a-zA-Z]", "")
            .toLowerCase();

        if (cleanWord.length() > 0) {
          word.set(cleanWord);
          context.write(word, one);
        }
      }
    }
  }

  // COMBINER: Local aggregation (same logic as reducer)
  // This runs on each mapper node BEFORE shuffle
  public static class IntSumCombiner
      extends Reducer<Text, IntWritable, Text, IntWritable> {

    private IntWritable result = new IntWritable();

    public void reduce(Text key, Iterable<IntWritable> values, Context context)
        throws IOException, InterruptedException {

      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);

      // Output: (word, local_count)
      // e.g., ("the", 50) instead of 50 individual ("the", 1) records
      context.write(key, result);
    }
  }

  // REDUCER: Final aggregation across all mappers
  public static class IntSumReducer
      extends Reducer<Text, IntWritable, Text, IntWritable> {

    private IntWritable result = new IntWritable();

    public void reduce(Text key, Iterable<IntWritable> values, Context context)
        throws IOException, InterruptedException {

      // Now values are pre-aggregated counts from combiners
      // e.g., values = [50, 30, 20] (from 3 different mappers)
      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);  // Total: 100
      context.write(key, result);
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "word count with combiner");

    job.setJarByClass(WordCountWithCombiner.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumCombiner.class);  // ← THE KEY LINE!
    job.setReducerClass(IntSumReducer.class);

    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);

    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));

    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
EOF
```

**Compile and package:**

```bash
# Set classpath
HADOOP_CP="/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/*"

# Compile
javac -cp $HADOOP_CP WordCountWithCombiner.java

# Create JAR
jar cvf wordcount-combiner.jar WordCountWithCombiner*.class
```

**Expected output:**

```
added manifest
adding: WordCountWithCombiner.class(in = 1234) (out= 678)(deflated 45%)
adding: WordCountWithCombiner$TokenizerMapper.class(in = 2345) (out= 1234)(deflated 47%)
adding: WordCountWithCombiner$IntSumCombiner.class(in = 1456) (out= 789)(deflated 45%)
adding: WordCountWithCombiner$IntSumReducer.class(in = 1456) (out= 789)(deflated 45%)
```

**Run the job:**

```bash
# Ensure input data exists
hadoop fs -test -e /user/hadoop/input/shakespeare.txt || \
  hadoop fs -put /datasets/wordcount/shakespeare.txt /user/hadoop/input/

# Clean output directory
hadoop fs -rm -r /user/hadoop/output/wordcount_combiner 2>/dev/null

# Run the job
yarn jar wordcount-combiner.jar WordCountWithCombiner \
  /user/hadoop/input/shakespeare.txt \
  /user/hadoop/output/wordcount_combiner
```

**Expected output:**

```
...
25/11/15 11:00:00 INFO mapreduce.Job:  map 0% reduce 0%
25/11/15 11:00:10 INFO mapreduce.Job:  map 100% reduce 0%
25/11/15 11:00:20 INFO mapreduce.Job:  map 100% reduce 100%
...
25/11/15 11:00:25 INFO mapreduce.Job: Counters: 54
  Map-Reduce Framework
    Map input records=124456
    Map output records=904062
    Map output bytes=8645739
    Map output materialized bytes=950123  ← After combiner
    Combine input records=904062          ← Before combiner
    Combine output records=67534          ← After combiner (93% reduction!)
    Reduce input groups=25975
    Reduce output records=25975
```

**What just happened:**

```
MAPPER OUTPUT (before combiner):
  904,062 records
  e.g., ("the", 1), ("the", 1), ("the", 1), ... (1090 times for "the")

↓ COMBINER (local aggregation on each mapper)

COMBINER OUTPUT (after local aggregation):
  67,534 records (93% reduction!)
  e.g., ("the", 1090) (single record instead of 1090)

↓ SHUFFLE (network transfer)

REDUCER INPUT:
  Only 67,534 records transferred over network
  Instead of 904,062 records!

Network savings: 93% less data transferred!
```

**View results:**

```bash
hadoop fs -cat /user/hadoop/output/wordcount_combiner/part-r-00000 | head -10
```

**Expected output:**

```
a	548
abandon	2
abandoned	1
...
the	1090
```

---

### Exercise 2: Custom Partitioner (Alphabetical Distribution)

**Concept:** Distributing words to reducers based on first letter.

**Create the Java file:**

```bash
cat > WordCountWithPartitioner.java << 'EOF'
import java.io.IOException;
import java.util.StringTokenizer;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Partitioner;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCountWithPartitioner {

  // MAPPER (same as before)
  public static class TokenizerMapper
      extends Mapper<Object, Text, Text, IntWritable> {
    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {
      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        String cleanWord = itr.nextToken()
            .replaceAll("[^a-zA-Z]", "")
            .toLowerCase();
        if (cleanWord.length() > 0) {
          word.set(cleanWord);
          context.write(word, one);
        }
      }
    }
  }

  // CUSTOM PARTITIONER: Route based on first letter
  public static class AlphabetPartitioner
      extends Partitioner<Text, IntWritable> {

    @Override
    public int getPartition(Text key, IntWritable value, int numPartitions) {
      // Get first character
      String word = key.toString();
      if (word.length() == 0) return 0;

      char firstLetter = word.charAt(0);

      // Partition by alphabet ranges
      // a-f → 0, g-m → 1, n-s → 2, t-z → 3
      if (firstLetter >= 'a' && firstLetter <= 'f') {
        return 0 % numPartitions;
      } else if (firstLetter >= 'g' && firstLetter <= 'm') {
        return 1 % numPartitions;
      } else if (firstLetter >= 'n' && firstLetter <= 's') {
        return 2 % numPartitions;
      } else {
        return 3 % numPartitions;
      }
    }
  }

  // REDUCER (same as before)
  public static class IntSumReducer
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
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "word count with partitioner");

    job.setJarByClass(WordCountWithPartitioner.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumReducer.class);
    job.setReducerClass(IntSumReducer.class);

    // Set custom partitioner
    job.setPartitionerClass(AlphabetPartitioner.class);
    job.setNumReduceTasks(4);  // Must match partitioner logic!

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
javac -cp $HADOOP_CP WordCountWithPartitioner.java
jar cvf wordcount-partitioner.jar WordCountWithPartitioner*.class

hadoop fs -rm -r /user/hadoop/output/wordcount_partitioner 2>/dev/null

yarn jar wordcount-partitioner.jar WordCountWithPartitioner \
  /user/hadoop/input/shakespeare.txt \
  /user/hadoop/output/wordcount_partitioner
```

**Check output files:**

```bash
hadoop fs -ls /user/hadoop/output/wordcount_partitioner/
```

**Expected output:**

```
Found 5 items
-rw-r--r--   2 hadoop supergroup          0 2025-11-15 11:10 /user/hadoop/output/wordcount_partitioner/_SUCCESS
-rw-r--r--   2 hadoop supergroup      45678 2025-11-15 11:10 /user/hadoop/output/wordcount_partitioner/part-r-00000
-rw-r--r--   2 hadoop supergroup      54321 2025-11-15 11:10 /user/hadoop/output/wordcount_partitioner/part-r-00001
-rw-r--r--   2 hadoop supergroup      43210 2025-11-15 11:10 /user/hadoop/output/wordcount_partitioner/part-r-00002
-rw-r--r--   2 hadoop supergroup      56789 2025-11-15 11:10 /user/hadoop/output/wordcount_partitioner/part-r-00003
```

**View each partition:**

```bash
echo "=== Partition 0 (a-f) ==="
hadoop fs -cat /user/hadoop/output/wordcount_partitioner/part-r-00000 | head -5

echo "=== Partition 1 (g-m) ==="
hadoop fs -cat /user/hadoop/output/wordcount_partitioner/part-r-00001 | head -5

echo "=== Partition 2 (n-s) ==="
hadoop fs -cat /user/hadoop/output/wordcount_partitioner/part-r-00002 | head -5

echo "=== Partition 3 (t-z) ==="
hadoop fs -cat /user/hadoop/output/wordcount_partitioner/part-r-00003 | head -5
```

**Expected output:**

```
=== Partition 0 (a-f) ===
a	548
abandon	2
abandoned	1
...
fair	83

=== Partition 1 (g-m) ===
gave	45
gentle	30
...
mine	123

=== Partition 2 (n-s) ===
nature	67
never	98
...
sweet	78

=== Partition 3 (t-z) ===
the	1090
thy	765
...
world	89
```

**What just happened:**

```
DEFAULT PARTITIONING (hash-based):
  hash("apple") % 4  = 2 → Reducer 2
  hash("banana") % 4 = 3 → Reducer 3
  hash("aardvark") % 4 = 1 → Reducer 1

  Result: Random distribution

CUSTOM PARTITIONING (alphabet-based):
  "apple"[0] = 'a' → Partition 0
  "banana"[0] = 'b' → Partition 0
  "aardvark"[0] = 'a' → Partition 0

  Result: All 'a-f' words in part-r-00000

Benefits:
  ✅ Organized output (alphabetical)
  ✅ Easy to find specific words
  ✅ Potential for better load balancing (if you know data distribution)
```

---

### Exercise 3: Inverted Index (Search Engine Pattern)

**Concept:** Creating a word-to-documents mapping (like Google's index).

**Setup sample documents:**

```bash
mkdir -p /tmp/docs

cat > /tmp/docs/doc1.txt << 'EOF'
The quick brown fox jumps over the lazy dog.
EOF

cat > /tmp/docs/doc2.txt << 'EOF'
The lazy cat sleeps all day long.
EOF

cat > /tmp/docs/doc3.txt << 'EOF'
The quick cat chases the lazy dog.
EOF

# Upload to HDFS
hadoop fs -rm -r /user/hadoop/input/docs 2>/dev/null
hadoop fs -mkdir -p /user/hadoop/input/docs
hadoop fs -put /tmp/docs/*.txt /user/hadoop/input/docs/
```

**Create InvertedIndex Java file:**

```bash
cat > InvertedIndex.java << 'EOF'
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.StringTokenizer;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class InvertedIndex {

  // MAPPER: Emit (word, document_name)
  public static class InvertedIndexMapper
      extends Mapper<Object, Text, Text, Text> {

    private Text word = new Text();
    private Text docName = new Text();

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {

      // Get the filename from the input split
      FileSplit fileSplit = (FileSplit) context.getInputSplit();
      String filename = fileSplit.getPath().getName();
      docName.set(filename);

      // Tokenize and emit (word, document)
      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        String cleanWord = itr.nextToken()
            .replaceAll("[^a-zA-Z]", "")
            .toLowerCase();

        if (cleanWord.length() > 0) {
          word.set(cleanWord);
          context.write(word, docName);
        }
      }
    }
  }

  // REDUCER: Aggregate unique documents for each word
  public static class InvertedIndexReducer
      extends Reducer<Text, Text, Text, Text> {

    public void reduce(Text key, Iterable<Text> values, Context context)
        throws IOException, InterruptedException {

      // Use HashSet to get unique documents
      Set<String> docs = new HashSet<>();
      for (Text doc : values) {
        docs.add(doc.toString());
      }

      // Output: word → [doc1.txt, doc2.txt, ...]
      context.write(key, new Text(docs.toString()));
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "inverted index");

    job.setJarByClass(InvertedIndex.class);
    job.setMapperClass(InvertedIndexMapper.class);
    job.setReducerClass(InvertedIndexReducer.class);

    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(Text.class);

    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));

    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
EOF
```

**Compile and run:**

```bash
javac -cp $HADOOP_CP InvertedIndex.java
jar cvf inverted-index.jar InvertedIndex*.class

hadoop fs -rm -r /user/hadoop/output/inverted_index 2>/dev/null

yarn jar inverted-index.jar InvertedIndex \
  /user/hadoop/input/docs \
  /user/hadoop/output/inverted_index
```

**View results:**

```bash
hadoop fs -cat /user/hadoop/output/inverted_index/part-r-00000
```

**Expected output:**

```
all	[doc2.txt]
brown	[doc1.txt]
cat	[doc2.txt, doc3.txt]
chases	[doc3.txt]
day	[doc2.txt]
dog	[doc1.txt, doc3.txt]
fox	[doc1.txt]
jumps	[doc1.txt]
lazy	[doc1.txt, doc2.txt, doc3.txt]
long	[doc2.txt]
over	[doc1.txt]
quick	[doc1.txt, doc3.txt]
sleeps	[doc2.txt]
the	[doc1.txt, doc2.txt, doc3.txt]
```

**What just happened:**

```
Input documents:
  doc1.txt: "The quick brown fox jumps over the lazy dog"
  doc2.txt: "The lazy cat sleeps all day long"
  doc3.txt: "The quick cat chases the lazy dog"

MAPPER OUTPUT (word, document):
  ("the", "doc1.txt"), ("quick", "doc1.txt"), ("brown", "doc1.txt"), ...
  ("the", "doc2.txt"), ("lazy", "doc2.txt"), ("cat", "doc2.txt"), ...
  ("the", "doc3.txt"), ("quick", "doc3.txt"), ("cat", "doc3.txt"), ...

SHUFFLE & SORT (group by word):
  "lazy" → [("lazy", "doc1.txt"), ("lazy", "doc2.txt"), ("lazy", "doc3.txt")]
  "cat"  → [("cat", "doc2.txt"), ("cat", "doc3.txt")]

REDUCER OUTPUT (word, unique documents):
  lazy → [doc1.txt, doc2.txt, doc3.txt]
  cat  → [doc2.txt, doc3.txt]

Use case: Search "lazy" → Returns: doc1.txt, doc2.txt, doc3.txt
```

**Real-world use:**
- Google's search engine uses inverted index
- Find all documents containing a specific term
- Rank documents by relevance (TF-IDF)

---

## Advanced Patterns

### Pattern 1: Top-N Query

**Problem:** Find top 10 most frequent words.

**Solution:** Use secondary sort or in-memory sorting in reducer.

```java
// In reducer:
Map<String, Integer> wordCounts = new TreeMap<>();

protected void reduce(Text key, Iterable<IntWritable> values, Context context) {
  int sum = 0;
  for (IntWritable val : values) {
    sum += val.get();
  }
  wordCounts.put(key.toString(), sum);
}

protected void cleanup(Context context) throws IOException, InterruptedException {
  // Sort by value (count) in descending order
  wordCounts.entrySet()
      .stream()
      .sorted((e1, e2) -> e2.getValue().compareTo(e1.getValue()))
      .limit(10)
      .forEach(entry -> {
        try {
          context.write(new Text(entry.getKey()), new IntWritable(entry.getValue()));
        } catch (Exception e) {
          e.printStackTrace();
        }
      });
}
```

---

### Pattern 2: Log Analysis

**Use case:** Analyze web server access logs.

**Example log format:**
```
192.168.1.10 - - [15/Nov/2025:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234
```

**Mapper emits:**
```java
String[] parts = line.split(" ");
String ip = parts[0];
String status = parts[8];
String path = parts[6];

context.write(new Text("STATUS_" + status), new IntWritable(1));
context.write(new Text("IP_" + ip), new IntWritable(1));
context.write(new Text("PATH_" + path), new IntWritable(1));
```

**Reducer outputs:**
```
IP_192.168.1.10     150
PATH_/index.html    500
STATUS_200          950
STATUS_404          50
```

---

## Performance Optimization Deep Dive

### Optimization 1: Compress Intermediate Data

**Problem:** Shuffle writes/reads GBs to disk.

**Solution:** Enable compression.

```java
Configuration conf = new Configuration();
conf.setBoolean("mapreduce.map.output.compress", true);
conf.setClass("mapreduce.map.output.compress.codec",
              org.apache.hadoop.io.compress.SnappyCodec.class,
              org.apache.hadoop.io.compress.CompressionCodec.class);
```

**Impact:** 3-4x reduction in disk I/O and network transfer.

---

### Optimization 2: Tune Memory Buffers

**Problem:** Small buffers cause frequent spills to disk.

**Solution:** Increase buffer sizes.

```java
conf.set("mapreduce.task.io.sort.mb", "200");  // Default: 100MB
conf.set("mapreduce.map.sort.spill.percent", "0.9");  // Default: 0.8
```

**Impact:** Fewer spills = less disk I/O.

---

### Optimization 3: Use Combiners (When Possible)

**When to use:**
- Aggregation functions (SUM, COUNT, MAX, MIN)
- Commutative and associative operations

**When NOT to use:**
- Median, average (not associative)
- Operations that require all values

---

### Optimization 4: Adjust Parallelism

```java
// More reducers for large datasets
job.setNumReduceTasks(10);  // Default: 1

// More mappers (controlled by split size)
FileInputFormat.setMinInputSplitSize(job, 64 * 1024 * 1024);  // 64MB
FileInputFormat.setMaxInputSplitSize(job, 128 * 1024 * 1024); // 128MB
```

---

## Key Takeaways

✅ **Shuffle is the bottleneck** - minimize data transfer with Combiners

✅ **Combiners reduce network traffic by 90%+** - use them for aggregations

✅ **Partitioners control data distribution** - customize for specific needs

✅ **Custom comparators change sort order** - useful for top-N queries

✅ **Compression saves I/O** - always enable for intermediate data

✅ **Tune parallelism based on data** - more mappers/reducers for large datasets

✅ **Inverted index is a fundamental pattern** - used in search engines

---

## Common Issues and Solutions

### Issue 1: "OutOfMemoryError" in Reducer

**Cause:** Reducer holds too much data in memory.

**Solution:**
```java
// Process data in streaming fashion
protected void reduce(Text key, Iterable<IntWritable> values, Context context) {
  // Don't do this:
  // List<Integer> allValues = new ArrayList<>();
  // for (IntWritable val : values) {
  //   allValues.add(val.get());  // Loads everything into memory!
  // }

  // Do this instead (streaming):
  int sum = 0;
  for (IntWritable val : values) {
    sum += val.get();  // Process one at a time
  }
  context.write(key, new IntWritable(sum));
}
```

---

### Issue 2: Combiner Not Being Used

**Symptom:** Combine input/output records are the same in job counters.

**Cause:** Combiner requires commutative/associative operation.

**Solution:** Verify combiner logic matches reducer logic.

---

## Quick Reference Card

```java
// ====================
// COMBINER
// ====================
job.setCombinerClass(MyCombiner.class);

// ====================
// PARTITIONER
// ====================
job.setPartitionerClass(MyPartitioner.class);
job.setNumReduceTasks(4);

// ====================
// CUSTOM COMPARATOR
// ====================
job.setSortComparatorClass(MyComparator.class);

// ====================
// COMPRESSION
// ====================
conf.setBoolean("mapreduce.map.output.compress", true);
conf.setClass("mapreduce.map.output.compress.codec", SnappyCodec.class, CompressionCodec.class);

// ====================
// MEMORY TUNING
// ====================
conf.set("mapreduce.task.io.sort.mb", "200");
conf.set("mapreduce.reduce.memory.mb", "2048");

// ====================
// PARALLELISM
// ====================
job.setNumReduceTasks(10);
FileInputFormat.setMaxInputSplitSize(job, 128 * 1024 * 1024);
```

---

## Next Steps

**You've mastered Advanced MapReduce!** Now you can:

1. **Move to Tutorial 08** - Integration Project (combining all technologies)
2. **Experiment more:**
   - Implement secondary sorting
   - Build a recommendation engine with MapReduce
   - Optimize existing jobs with combiners and compression
3. **Learn more:**
   - MapReduce Design Patterns book
   - Distributed Cache for join optimizations
   - Custom InputFormat/OutputFormat

---

**Exit container:** Type `exit` and press Enter
