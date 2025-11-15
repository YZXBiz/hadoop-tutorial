#!/bin/bash

set -e

echo "========================================="
echo "Starting Hadoop Cluster"
echo "========================================="

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi

# Start all services
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 10

# Check NameNode health
echo ""
echo "Checking NameNode health..."
while ! docker-compose exec -T namenode hadoop fs -ls / &>/dev/null; do
    echo "  NameNode not ready yet, waiting..."
    sleep 5
done
echo "  NameNode is healthy"

# Check ResourceManager health
echo "Checking ResourceManager health..."
while ! docker-compose exec -T resourcemanager curl -s http://localhost:8088/cluster &>/dev/null; do
    echo "  ResourceManager not ready yet, waiting..."
    sleep 5
done
echo "  ResourceManager is healthy"

# Create necessary HDFS directories
echo ""
echo "Creating HDFS directories..."
docker-compose exec -T namenode bash -c '
  hadoop fs -mkdir -p /user/hadoop/input 2>/dev/null || true
  hadoop fs -mkdir -p /user/hadoop/output 2>/dev/null || true
  hadoop fs -mkdir -p /user/sqoop 2>/dev/null || true
  hadoop fs -mkdir -p /user/hive/warehouse 2>/dev/null || true
  hadoop fs -mkdir -p /hbase 2>/dev/null || true
  hadoop fs -chmod -R 777 /user 2>/dev/null || true
'

echo ""
echo "========================================="
echo "Hadoop Cluster Started Successfully!"
echo "========================================="
echo ""
echo "Web UIs Available:"
echo "  - NameNode:        http://localhost:9870"
echo "  - ResourceManager: http://localhost:8088"
echo "  - HistoryServer:   http://localhost:19888"
echo "  - HiveServer2:     http://localhost:10002"
echo "  - HBase Master:    http://localhost:16010"
echo ""
echo "Next steps:"
echo "  1. Load sample data: bash scripts/load-sample-data.sh"
echo "  2. Run tutorials: cd tutorials/01-hdfs-basics && cat README.md"
echo "  3. View logs: docker-compose logs -f"
echo ""
