#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$PATH

# Wait for HDFS and Metastore
echo "Waiting for HDFS..."
while ! nc -z namenode 9000 2>/dev/null; do
    sleep 1
done

echo "Waiting for Hive Metastore..."
while ! nc -z hive-metastore 9083 2>/dev/null; do
    sleep 1
done

# Start HiveServer2
echo "Starting HiveServer2..."
hiveserver2
