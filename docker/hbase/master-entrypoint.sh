#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HBASE_HOME=/opt/hbase
export CLASSPATH=$HBASE_HOME/lib:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$CLASSPATH
export PATH=$HADOOP_HOME/bin:$HBASE_HOME/bin:$PATH

# Wait for ZooKeeper and HDFS
echo "Waiting for ZooKeeper..."
while ! nc -z zookeeper 2181 2>/dev/null; do
    sleep 1
done

echo "Waiting for HDFS..."
while ! nc -z namenode 9000 2>/dev/null; do
    sleep 1
done

# Start HBase Master
echo "Starting HBase Master..."
hbase master start
