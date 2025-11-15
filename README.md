# Hadoop Learning Environment

A comprehensive Docker-based Hadoop ecosystem setup for learning distributed data processing. This environment includes the complete Hadoop stack with Hive, HBase, Pig, and Sqoop.

## Quick Start

```bash
# Start the entire Hadoop cluster
docker-compose up -d

# Wait for services to initialize (check logs)
docker-compose logs -f

# Once services are running, access:
# - NameNode: http://localhost:9870
# - ResourceManager: http://localhost:8088
# - HiveServer2: http://localhost:10002
# - HBase Master: http://localhost:16010

# Load sample data
bash scripts/load-sample-data.sh

# Run tutorials
cd tutorials/01-hdfs-basics
bash commands.sh
```

## Environment Components

### Hadoop Core
- **NameNode** - HDFS master (metadata, file system namespace)
- **DataNode** (2x) - HDFS storage nodes
- **ResourceManager** - YARN job scheduler and resource manager
- **NodeManager** - YARN node agent on worker nodes
- **HistoryServer** - MapReduce job history tracking

### Hive (SQL on Hadoop)
- **HiveServer2** - SQL query engine
- **Hive Metastore** - Metadata storage
- **MariaDB** - Metastore database backend

### HBase (NoSQL)
- **HBase Master** - Region master and metadata server
- **HBase RegionServer** - Data node for HBase
- **ZooKeeper** - Distributed coordination service

### Additional Tools
- **Pig** - Data flow language
- **Sqoop** - ETL tool for MySQL ↔ HDFS data transfer

## Key Ports

| Service | Port | Purpose |
|---------|------|---------|
| NameNode Web UI | 9870 | HDFS monitoring |
| ResourceManager UI | 8088 | YARN monitoring |
| HistoryServer | 19888 | MapReduce job history |
| HiveServer2 Thrift | 10000 | SQL client connections |
| HiveServer2 Web UI | 10002 | Hive monitoring |
| HBase Master UI | 16010 | HBase monitoring |
| ZooKeeper | 2181 | Coordination service |
| MariaDB | 3306 | Metastore database |

## Directory Structure

```
├── docker/                  # Dockerfiles for each service
├── config/                  # Hadoop/Hive/HBase configuration files
├── data/                    # Persistent volumes (gitignored)
├── datasets/                # Sample datasets for learning
├── tutorials/               # Step-by-step learning projects
├── scripts/                 # Helper scripts
└── docs/                    # Additional documentation
```

## Tutorials

Learn Hadoop progressively through these tutorials:

### Beginner Level
1. **01-hdfs-basics** - Upload, download, and manage files in HDFS
2. **02-mapreduce-wordcount** - Classic WordCount MapReduce example
3. **03-hive-queries** - Basic SQL queries on structured data

### Intermediate Level
4. **04-hbase-operations** - NoSQL CRUD operations
5. **05-pig-scripts** - Data transformation with Pig language
6. **06-sqoop-etl** - Import/export data between MySQL and HDFS

### Advanced Level
7. **07-advanced-mapreduce** - Complex joins, custom reducers
8. **08-integration-project** - Full data pipeline using multiple tools

## Sample Datasets

- **wordcount/** - Text files for processing (Shakespeare, logs)
- **structured/** - CSV files (employees, sales, customers)
- **logs/** - Web server and application logs
- **climate/** - Time series sensor data

## Common Commands

### Start/Stop Services
```bash
docker-compose up -d          # Start all services
docker-compose down           # Stop all services
docker-compose logs -f        # View live logs
docker-compose ps             # Check service status
```

### Access Services
```bash
# Interactive Hadoop shell
docker-compose exec namenode bash

# HiveServer2 client
docker-compose exec hive-server hive

# HBase shell
docker-compose exec hbase-master hbase shell

# Pig shell
docker-compose exec namenode pig
```

### HDFS Commands
```bash
# List files
docker-compose exec namenode hadoop fs -ls /

# Upload file
docker-compose exec namenode hadoop fs -put /path/to/file /hdfs/path

# Download file
docker-compose exec namenode hadoop fs -get /hdfs/path /path/to/download
```

### Run MapReduce Job
```bash
docker-compose exec namenode yarn jar \
  /path/to/jar/wordcount.jar \
  /input/path /output/path
```

## System Requirements

- Docker and Docker Compose
- ~4GB RAM available (can adjust via docker-compose.yml)
- ~10GB disk space for data volumes
- macOS, Linux, or Windows with WSL2

## Troubleshooting

See `docs/troubleshooting.md` for common issues and solutions.

## Architecture

See `docs/architecture.md` for detailed system design and component interactions.

## References

- [Hadoop Documentation](https://hadoop.apache.org/docs/)
- [Hive Documentation](https://hive.apache.org/)
- [HBase Documentation](https://hbase.apache.org/)
- [Pig Documentation](https://pig.apache.org/)
- [Sqoop Documentation](https://sqoop.apache.org/)

## License

This learning environment is provided as-is for educational purposes.
