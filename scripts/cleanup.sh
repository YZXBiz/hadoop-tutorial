#!/bin/bash

echo "========================================="
echo "Cleaning up Hadoop Cluster"
echo "========================================="
echo ""
echo "This will remove all containers, volumes, and cached data."
echo "WARNING: This cannot be undone!"
echo ""
read -p "Are you sure? (yes/no): " -r
echo

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Stopping containers..."
    docker-compose down -v

    echo "Removing local data volumes..."
    rm -rf ./data/namenode/*
    rm -rf ./data/datanode1/*
    rm -rf ./data/datanode2/*
    rm -rf ./data/hbase/*
    rm -rf ./data/mariadb/*
    rm -rf ./data/zookeeper/*

    echo ""
    echo "========================================="
    echo "Cleanup Complete!"
    echo "========================================="
    echo ""
    echo "To start fresh: bash scripts/start.sh"
    echo ""
else
    echo "Cleanup cancelled."
    exit 1
fi
