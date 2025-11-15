#!/bin/bash

set -e

# Start SSH
service ssh start

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Format namenode if needed
if [ ! -d "/hadoop/dfs/name/current" ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force -nonInteractive
fi

# Start NameNode
echo "Starting NameNode..."
hdfs namenode
