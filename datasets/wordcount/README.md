# Word Count Dataset

This directory contains sample text files for MapReduce word count exercises.

## Files

- **shakespeare.txt** - Excerpts from works of William Shakespeare
- **sample-logs.txt** - Sample web server access logs

## Usage

To use these files in tutorials:

```bash
# Upload to HDFS
docker-compose exec namenode hadoop fs -put /datasets/wordcount/shakespeare.txt /input/

# Run word count MapReduce job
docker-compose exec namenode yarn jar \
  /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount \
  /input/shakespeare.txt /output/
```

## Processing

These files are useful for:
- Learning basic MapReduce with word count
- Understanding text processing
- Exploring distributed computing concepts
