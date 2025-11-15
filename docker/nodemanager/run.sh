#!/bin/bash

set -e

# Start SSH
service ssh start

# Set environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Wait for ResourceManager
echo "Waiting for ResourceManager..."
while ! nc -z resourcemanager 8032 2>/dev/null; do
    sleep 1
done

echo "ResourceManager is ready. Starting NodeManager..."

# Start NodeManager
yarn nodemanager
