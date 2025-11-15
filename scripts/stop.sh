#!/bin/bash

echo "========================================="
echo "Stopping Hadoop Cluster"
echo "========================================="

docker-compose down

echo ""
echo "========================================="
echo "Hadoop Cluster Stopped"
echo "========================================="
echo ""
echo "To restart: bash scripts/start.sh"
echo ""
