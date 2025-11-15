#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HBASE_HOME=/opt/hbase
export CLASSPATH=$HBASE_HOME/lib:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$CLASSPATH
export PATH=$HADOOP_HOME/bin:$HBASE_HOME/bin:$PATH

# Wait for HBase Master
echo "Waiting for HBase Master..."
while ! nc -z hbase-master 16000 2>/dev/null; do
    sleep 1
done

# Start HBase RegionServer
echo "Starting HBase RegionServer..."
hbase regionserver start
