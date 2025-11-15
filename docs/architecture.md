# Hadoop Learning Environment Architecture

## System Overview

This setup creates a complete, distributed Hadoop ecosystem environment optimized for learning and experimentation.

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│            Docker Network: hadoop-net                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         HDFS (Hadoop Distributed File System)   │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  NameNode (NN)     - Master                     │  │
│  │  ├─ Port 9870      - Web UI                     │  │
│  │  ├─ Port 9000      - IPC                        │  │
│  │  └─ HDFS HA:       - Name space, fsimage       │  │
│  │                                                  │  │
│  │  DataNode 1 (DN1)  - Storage                    │  │
│  │  ├─ Port 9864      - Data transfer              │  │
│  │  └─ /hadoop/dfs/data - Block storage            │  │
│  │                                                  │  │
│  │  DataNode 2 (DN2)  - Storage                    │  │
│  │  └─ Replication factor: 2                       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │      YARN (Yet Another Resource Negotiator)     │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  ResourceManager (RM) - Master                  │  │
│  │  ├─ Port 8088        - Web UI                   │  │
│  │  ├─ Port 8032        - IPC                      │  │
│  │  └─ Job Scheduling                              │  │
│  │                                                  │  │
│  │  NodeManager (NM)    - Worker                   │  │
│  │  ├─ Port 8042        - Web UI                   │  │
│  │  └─ Container mgmt                              │  │
│  │                                                  │  │
│  │  HistoryServer (HS)  - Job history              │  │
│  │  └─ Port 19888       - Web UI                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │      Hive (SQL on Hadoop)                       │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  HiveServer2 (HS2)   - SQL Engine               │  │
│  │  ├─ Port 10000       - Thrift client            │  │
│  │  ├─ Port 10002       - Web UI                   │  │
│  │  └─ Query execution                             │  │
│  │                                                  │  │
│  │  Hive Metastore      - Metadata                 │  │
│  │  ├─ Port 9083        - Thrift                   │  │
│  │  └─ Table definitions                           │  │
│  │                                                  │  │
│  │  MariaDB             - Metastore DB             │  │
│  │  └─ Port 3306        - MySQL protocol           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │      HBase (NoSQL Database)                     │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  HBase Master        - Region assignment        │  │
│  │  ├─ Port 16010       - Web UI                   │  │
│  │  └─ Metadata mgmt                               │  │
│  │                                                  │
│  │  HBase RegionServer  - Data storage             │  │
│  │  └─ Port 16030       - Web UI                   │  │
│  │                                                  │
│  │  ZooKeeper           - Coordination             │  │
│  │  └─ Port 2181        - Client port              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

### Import Pipeline (MySQL → HDFS)
```
MySQL Database
    ↓
  Sqoop
    ↓
HDFS Storage
    ↓
Hive Tables
```

### Processing Pipeline (HDFS → Results)
```
Input Files (HDFS)
    ↓
MapReduce Jobs
    ↓
Intermediate Output
    ↓
Hive SQL Processing
    ↓
HBase Results Store
```

## Container Specifications

### NameNode Container
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + Java 8
- **Volumes**: `/hadoop/dfs/name` (persistent)
- **Ports**: 9870 (Web), 9000 (IPC), 50070 (Legacy)
- **Memory**: 1GB recommended
- **CPU**: 1 core recommended

### DataNode Containers (2x)
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + Java 8
- **Volumes**: `/hadoop/dfs/data` (persistent)
- **Ports**: 9864 (Data), 50075 (Legacy)
- **Memory**: 512MB each recommended
- **CPU**: 0.5 cores each recommended

### ResourceManager Container
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + Java 8
- **Ports**: 8088 (Web), 8032 (IPC)
- **Memory**: 1GB recommended
- **CPU**: 1 core recommended

### NodeManager Container
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + Java 8
- **Ports**: 8042 (Web)
- **Memory**: 512MB recommended
- **CPU**: 1 core recommended

### HiveServer2 Container
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + Hive 3.1.3 + Java 8
- **Ports**: 10000 (Thrift), 10002 (Web UI)
- **Memory**: 1GB recommended
- **CPU**: 1 core recommended

### HBase Master Container
- **Image**: Ubuntu 20.04 + Hadoop 3.3.6 + HBase 2.5.3 + Java 8
- **Ports**: 16010 (Web), 16000 (IPC)
- **Volumes**: `/hbase` (persistent)
- **Memory**: 1GB recommended
- **CPU**: 1 core recommended

### ZooKeeper Container
- **Image**: Ubuntu 20.04 + ZooKeeper 3.8.1 + Java 8
- **Ports**: 2181 (Client)
- **Volumes**: `/var/lib/zookeeper` (persistent)
- **Memory**: 512MB recommended
- **CPU**: 0.5 cores recommended

### MariaDB Container
- **Image**: MariaDB 10.6
- **Ports**: 3306 (MySQL)
- **Volumes**: `/var/lib/mysql` (persistent)
- **Memory**: 512MB recommended
- **CPU**: 0.5 cores recommended

## Network Configuration

### Docker Network
- **Type**: Bridge network
- **Name**: `hadoop-net`
- **DNS**: Container names resolve automatically

### Service Discovery
- NameNode: `hdfs://namenode:9000`
- HiveServer2: `thrift://hive-server:10000`
- HBase Master: `hbase-master:16000`
- ZooKeeper: `zookeeper:2181`
- MariaDB: `mariadb:3306`

## Storage Architecture

### HDFS Storage
```
/hadoop/dfs/
├── name/              (NameNode metadata)
│   └── current/
│       ├── fsimage
│       └── edits
└── data/              (DataNode blocks)
    ├── BP-...
    └── ...
```

### Data Volumes
```
./data/
├── namenode/          (1GB+)
├── datanode1/         (500MB+)
├── datanode2/         (500MB+)
├── hbase/             (500MB+)
├── mariadb/           (200MB+)
└── zookeeper/         (100MB+)
```

## Configuration Management

### Configuration Files
- `config/hadoop/` - HDFS, YARN, MapReduce configs
- `config/hive/` - Hive SQL engine configuration
- `config/hbase/` - HBase database configuration

### Environment Variables
- `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64`
- `HADOOP_HOME=/opt/hadoop`
- `HIVE_HOME=/opt/hive`
- `HBASE_HOME=/opt/hbase`

## Security Considerations

### Current Setup
- **Kerberos**: Disabled (learning environment)
- **LDAP**: Disabled
- **SSL/TLS**: Not configured
- **Firewall**: Docker network isolation only

### Production Considerations
For production deployments:
- Enable Kerberos authentication
- Configure SSL/TLS encryption
- Implement role-based access control (RBAC)
- Set up firewall rules
- Use private networking
- Enable audit logging

## Resource Allocation

### Recommended System Requirements
- **CPU**: 4+ cores (2 for minimum)
- **RAM**: 8GB+ (4GB minimum)
- **Disk**: 20GB+ (10GB minimum)

### Container Resource Limits
```yaml
namenode:         2GB RAM, 1 CPU
datanode1:        1GB RAM, 1 CPU
datanode2:        1GB RAM, 1 CPU
resourcemanager:  1GB RAM, 1 CPU
nodemanager:      1GB RAM, 1 CPU
hive-server:      1GB RAM, 1 CPU
hbase-master:     1GB RAM, 1 CPU
hbase-regionserver: 512MB RAM, 0.5 CPU
zookeeper:        512MB RAM, 0.5 CPU
mariadb:          512MB RAM, 0.5 CPU
```

## Data Replication Strategy

### HDFS Replication
- **Default factor**: 2
- **Block size**: 128MB (configurable)
- **Rack awareness**: Enabled for multi-node clusters

### HBase Replication
- **Write-Ahead Log (WAL)**: Enabled
- **Memstore**: In-memory buffer (configurable)
- **HFile**: Persistent storage on HDFS

## Performance Optimization

### HDFS Tuning
- Network optimizations
- Block caching strategies
- Short-circuit local reads

### YARN Tuning
- Container resource allocation
- Queue scheduling
- CPU and memory limits

### Hive Optimization
- Vectorized query execution
- Cost-based optimization
- Partition pruning

### HBase Optimization
- Bloom filters
- Compression
- Cache sizing

## Monitoring and Observability

### Web UIs
- **NameNode**: http://localhost:9870
- **ResourceManager**: http://localhost:8088
- **HistoryServer**: http://localhost:19888
- **HiveServer2**: http://localhost:10002
- **HBase Master**: http://localhost:16010

### Logging
- Application logs: `docker-compose logs <service>`
- HDFS logs: `/opt/hadoop/logs/`
- HBase logs: `/opt/hbase/logs/`

### Metrics
- Resource usage
- Job performance
- Queue status
- Block distribution

## Scalability

### Current Limitations
- Single-machine deployment
- No high availability (HA)
- Basic resource allocation

### Scaling Paths
1. **Horizontal**: Add more DataNode containers
2. **Vertical**: Increase container resource limits
3. **HA**: Configure NameNode high availability
4. **Federation**: Multiple NameNode instances

## Integration Points

### External Systems
- **MySQL**: Via MariaDB container
- **HDFS**: Standard port 9000
- **HiveServer2**: Thrift protocol port 10000
- **HBase**: Standard ports 16000, 16010

### Client Connectivity
- **Beeline**: Connect to HiveServer2
- **HBase Shell**: Connect to HBase Master
- **Pig**: Process data with data flows
- **Sqoop**: ETL from MySQL to HDFS
