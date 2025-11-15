#!/bin/bash

set -e

# Start SSH
service ssh start

# Set environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Wait for NameNode to be ready
echo "Waiting for NameNode to be ready..."
while ! nc -z namenode 9000 2>/dev/null; do
    sleep 1
done

echo "NameNode is ready. Starting DataNode..."

# Start DataNode
hdfs datanode
