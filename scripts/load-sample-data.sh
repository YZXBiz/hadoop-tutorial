#!/bin/bash

set -e

echo "========================================="
echo "Loading Sample Data into HDFS"
echo "========================================="

# Create directories
echo "Creating directories..."
docker-compose exec -T namenode bash -c '
  hadoop fs -mkdir -p /datasets/wordcount
  hadoop fs -mkdir -p /datasets/structured
  hadoop fs -mkdir -p /datasets/logs
  hadoop fs -mkdir -p /datasets/climate
  hadoop fs -mkdir -p /input
  echo "Directories created"
'

# Upload WordCount dataset
echo ""
echo "Uploading text files..."
docker-compose exec -T namenode bash -c '
  hadoop fs -put /datasets/wordcount/*.txt /datasets/wordcount/ 2>/dev/null || true
  echo "Text files uploaded"
'

# Upload structured data (CSV files)
echo "Uploading CSV files..."
docker-compose exec -T namenode bash -c '
  hadoop fs -put /datasets/structured/*.csv /datasets/structured/ 2>/dev/null || true
  echo "CSV files uploaded"
'

# Upload logs
echo "Uploading log files..."
docker-compose exec -T namenode bash -c '
  hadoop fs -put /datasets/logs/*.txt /datasets/logs/ 2>/dev/null || true
  echo "Log files uploaded"
'

# Upload climate data
echo "Uploading climate data..."
docker-compose exec -T namenode bash -c '
  hadoop fs -put /datasets/climate/*.csv /datasets/climate/ 2>/dev/null || true
  echo "Climate data uploaded"
'

# Verify
echo ""
echo "========================================="
echo "Verifying uploaded data..."
echo "========================================="
docker-compose exec -T namenode bash -c '
  echo "WordCount files:"
  hadoop fs -ls -h /datasets/wordcount/ | tail -1
  echo ""
  echo "Structured data:"
  hadoop fs -ls -h /datasets/structured/ | tail -1
  echo ""
  echo "Log files:"
  hadoop fs -ls -h /datasets/logs/ | tail -1
  echo ""
  echo "Climate data:"
  hadoop fs -ls -h /datasets/climate/ | tail -1
'

echo ""
echo "========================================="
echo "Sample Data Loaded Successfully!"
echo "========================================="
echo ""
echo "Data locations:"
echo "  - Text files: hdfs://namenode:9000/datasets/wordcount"
echo "  - CSV files:  hdfs://namenode:9000/datasets/structured"
echo "  - Logs:       hdfs://namenode:9000/datasets/logs"
echo "  - Climate:    hdfs://namenode:9000/datasets/climate"
echo ""
