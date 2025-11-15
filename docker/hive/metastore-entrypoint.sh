#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$PATH

# Wait for MariaDB
echo "Waiting for MariaDB..."
while ! nc -z mariadb 3306 2>/dev/null; do
    sleep 1
done

# Initialize metastore schema if needed
echo "Initializing Hive Metastore..."
schematool -dbType mysql -initSchema 2>/dev/null || true

# Start Hive Metastore
echo "Starting Hive Metastore..."
hive --service metastore
