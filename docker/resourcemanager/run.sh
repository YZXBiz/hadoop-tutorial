#!/bin/bash

set -e

# Start SSH
service ssh start

# Set environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Wait for NameNode
echo "Waiting for NameNode..."
while ! nc -z namenode 9000 2>/dev/null; do
    sleep 1
done

echo "NameNode is ready. Starting ResourceManager..."

# Start ResourceManager
yarn resourcemanager
