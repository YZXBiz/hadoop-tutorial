#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Create history directory in HDFS
echo "Waiting for HDFS to be ready..."
while ! nc -z namenode 9000 2>/dev/null; do
    sleep 1
done

echo "Creating job history directory..."
hadoop fs -mkdir -p /user/history 2>/dev/null || true
hadoop fs -chmod 777 /user/history 2>/dev/null || true

echo "Starting HistoryServer..."
mapred historyserver
