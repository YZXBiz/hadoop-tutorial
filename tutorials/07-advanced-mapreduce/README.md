# Tutorial 07: Advanced MapReduce

Learn advanced MapReduce techniques for complex data processing.

## Learning Objectives

- Implement custom Mapper and Reducer logic
- Handle multiple input/output types
- Implement Combiner for optimization
- Work with Partitioners and Comparators
- Process structured data with multiple fields
- Optimize MapReduce performance

## Prerequisites

- Java Development Kit
- Understanding of basic MapReduce
- Compiled JAR files ready

## Advanced Concepts

### Combiner Pattern

A Combiner is like a local Reducer that runs on each Mapper output. It reduces network traffic.

```java
public class AdvancedWordCount {

  public static class TokenizerMapper
      extends Mapper<Object, Text, Text, IntWritable> {
    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {
      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        word.set(itr.nextToken().replaceAll("[^a-zA-Z]", "").toLowerCase());
        if (word.getLength() > 0) {
          context.write(word, one);
        }
      }
    }
  }

  // Combiner - same logic as reducer in this case
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
      context.write(key, result);
    }
  }

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
    Job job = Job.getInstance(conf, "advanced word count");
    job.setJarByClass(AdvancedWordCount.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumCombiner.class);  // Add combiner
    job.setReducerClass(IntSumReducer.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
```

### Custom Partitioner

Partitioner determines which reducer receives which key.

```java
public class KeyPartitioner extends Partitioner<Text, IntWritable> {
  @Override
  public int getPartition(Text key, IntWritable value,
      int numPartitions) {
    // Partition by first character
    char firstChar = key.toString().charAt(0);
    if (firstChar >= 'a' && firstChar <= 'g') {
      return 0;
    } else if (firstChar >= 'h' && firstChar <= 'n') {
      return 1;
    } else if (firstChar >= 'o' && firstChar <= 'u') {
      return 2;
    } else {
      return 3;
    }
  }
}
```

Usage:
```java
job.setPartitionerClass(KeyPartitioner.class);
job.setNumReduceTasks(4);
```

### Custom Comparator

Sort keys in a custom order.

```java
public class ReverseComparator implements RawComparator<Text> {
  private final Text.Comparator comparator = new Text.Comparator();

  @Override
  public int compare(byte[] b1, int s1, int l1, byte[] b2, int s2, int l2) {
    return -comparator.compare(b1, s1, l1, b2, s2, l2);  // Reverse
  }

  @Override
  public int compare(Text a, Text b) {
    return -a.compareTo(b);  // Reverse
  }
}
```

Usage:
```java
job.setSortComparatorClass(ReverseComparator.class);
```

## Practical Example: Inverted Index

Create a reverse mapping from words to documents.

```java
public class InvertedIndex {

  public static class InvertedIndexMapper
      extends Mapper<Object, Text, Text, Text> {
    private Text word = new Text();
    private Text docInfo = new Text();

    @Override
    protected void setup(Context context) throws IOException, InterruptedException {
      // Setup called once per mapper
    }

    public void map(Object key, Text value, Context context)
        throws IOException, InterruptedException {
      // key is document name from input split
      String docName = ((FileSplit) context.getInputSplit())
          .getPath().getName();

      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        String token = itr.nextToken()
            .replaceAll("[^a-zA-Z0-9]", "")
            .toLowerCase();
        if (token.length() > 0) {
          word.set(token);
          docInfo.set(docName);
          context.write(word, docInfo);
        }
      }
    }
  }

  public static class InvertedIndexReducer
      extends Reducer<Text, Text, Text, Text> {

    public void reduce(Text key, Iterable<Text> values, Context context)
        throws IOException, InterruptedException {
      Set<String> docs = new HashSet<>();
      for (Text doc : values) {
        docs.add(doc.toString());
      }
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
```

## Log Analysis Example

Process access logs to find statistics.

```java
public class LogAnalyzer {

  public static class LogMapper
      extends Mapper<LongWritable, Text, Text, Text> {

    public void map(LongWritable key, Text value, Context context)
        throws IOException, InterruptedException {
      String line = value.toString();
      String[] parts = line.split(" ");

      if (parts.length >= 9) {
        String ip = parts[0];
        String statusCode = parts[8];
        String path = parts[6];

        context.write(new Text("STATUS_" + statusCode), new Text("1"));
        context.write(new Text("IP_" + ip), new Text("1"));
        context.write(new Text("PATH_" + path), new Text("1"));
      }
    }
  }

  public static class LogReducer
      extends Reducer<Text, Text, Text, IntWritable> {

    public void reduce(Text key, Iterable<Text> values, Context context)
        throws IOException, InterruptedException {
      int count = 0;
      for (Text val : values) {
        count += Integer.parseInt(val.toString());
      }
      context.write(key, new IntWritable(count));
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

## Compilation and Execution

```bash
# Compile
javac -cp /opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/* \
  LogAnalyzer.java

# Create JAR
jar cvf loganalyzer.jar LogAnalyzer*.class

# Run job
hadoop fs -mkdir -p /input
hadoop fs -put /datasets/logs/access_logs.txt /input/

yarn jar loganalyzer.jar LogAnalyzer /input /output/log_analysis

# View results
hadoop fs -cat /output/log_analysis/part-r-00000 | head -20
```

## Performance Optimization Tips

1. **Use Combiners**: Reduce network traffic significantly
2. **Compress intermediate data**: Set in job configuration
3. **Tune parallelism**: Adjust number of mappers/reducers
4. **Avoid shuffle overhead**: Design jobs to minimize reshuffling
5. **Use counters for monitoring**: Track progress and anomalies

```java
Counter counter = context.getCounter("APP_COUNTERS", "TOTAL_WORDS");
counter.increment(1);
```

## Exercises

1. Implement inverted index for multiple documents
2. Create a log analyzer that extracts statistics
3. Implement a job that finds top N items
4. Build a custom partitioner for load balancing
5. Optimize a MapReduce job using Combiner

## Debugging

```bash
# View logs
hadoop logs -applicationId <app_id>

# Enable debugging
-Dmapreduce.map.debug.script=/path/to/debug.sh

# Check failed tasks
mapred task -kill <task_id>
```

## Further Reading

- MapReduce Design Patterns
- Custom Input/Output Formats
- Distributed Cache usage
