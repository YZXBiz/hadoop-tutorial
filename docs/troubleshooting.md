# Troubleshooting Guide

## Common Issues and Solutions

### 1. Containers Won't Start

**Symptom**: `docker-compose up` fails or containers crash immediately

**Diagnosis**:
```bash
docker-compose logs <service_name>
docker-compose ps
```

**Solutions**:

a) **Port conflicts**: Another service using the port
```bash
# Find what's using port 9870
lsof -i :9870
# Change port in docker-compose.yml or stop conflicting service
```

b) **Insufficient memory**:
```bash
# Check available memory
free -h
# Reduce container memory limits in docker-compose.yml
```

c) **Docker daemon issues**:
```bash
# Restart Docker
docker restart
# Or use desktop app's restart
```

### 2. NameNode Safe Mode

**Symptom**: HDFS operations fail with "in safe mode"

**Error**:
```
org.apache.hadoop.hdfs.server.namenode.SafeModeException: Cannot create file /...
```

**Solution**:
```bash
# Connect to NameNode and exit safe mode
docker-compose exec namenode bash
hdfs dfsadmin -safemode leave
```

### 3. DataNode Connection Issues

**Symptom**: DataNodes don't register with NameNode
- NameNode shows 0 live datanodes
- Block replication fails

**Diagnosis**:
```bash
# Check NameNode logs
docker-compose logs namenode | grep -i datanode

# Check DataNode logs
docker-compose logs datanode1
```

**Solutions**:

a) **Network connectivity**:
```bash
# Test connection from datanode to namenode
docker-compose exec datanode1 bash
nc -zv namenode 9000
```

b) **Configuration mismatch**:
```bash
# Verify core-site.xml has same values everywhere
cat config/hadoop/core-site.xml | grep "fs.defaultFS"
```

c) **Restart DataNodes**:
```bash
docker-compose restart datanode1 datanode2
```

### 4. HDFS Space Issues

**Symptom**: "Not enough space" errors

**Diagnosis**:
```bash
# Check HDFS usage
docker-compose exec namenode bash
hadoop fs -df -h

# Check container disk usage
docker exec namenode df -h
```

**Solutions**:

a) **Clean old files**:
```bash
# Remove old job outputs
hadoop fs -rm -r /output/*

# Clear logs
hadoop fs -rm -r /user/history/*
```

b) **Increase volume size**: Modify docker-compose.yml volumes

c) **Enable compression**:
```bash
# In mapred-site.xml
hadoop fs -cat /etc/hadoop/mapred-site.xml | grep compress
```

### 5. YARN ResourceManager Issues

**Symptom**: Jobs stuck or not running
- ResourceManager Web UI unavailable
- "Cannot contact ResourceManager"

**Diagnosis**:
```bash
# Check ResourceManager status
curl http://localhost:8088/cluster

# Check logs
docker-compose logs resourcemanager
docker-compose logs nodemanager
```

**Solutions**:

a) **Check memory allocation**:
```bash
# Verify yarn-site.xml
docker-compose exec resourcemanager bash
grep "yarn.nodemanager.resource.memory-mb" /etc/hadoop/conf/yarn-site.xml
```

b) **Restart YARN services**:
```bash
docker-compose restart resourcemanager nodemanager
```

c) **Kill stuck applications**:
```bash
docker-compose exec namenode bash
yarn application -list
yarn application -kill <app_id>
```

### 6. Hive Connection Problems

**Symptom**: Cannot connect to HiveServer2
- Connection timeout
- "Cannot connect to metastore"

**Diagnosis**:
```bash
# Check if HiveServer2 is listening
docker-compose exec hive-server bash
nc -zv localhost 10000

# Check metastore connection
docker-compose exec hive-metastore bash
nc -zv mariadb 3306
```

**Solutions**:

a) **Check MariaDB**:
```bash
# Verify MariaDB is running
docker-compose exec mariadb mysql -u hive -phive -e "SELECT 1"
```

b) **Initialize metastore schema**:
```bash
docker-compose exec hive-metastore bash
schematool -dbType mysql -initSchema
```

c) **Restart services in order**:
```bash
docker-compose restart mariadb
sleep 5
docker-compose restart hive-metastore
sleep 5
docker-compose restart hive-server
```

### 7. HBase Connectivity Issues

**Symptom**: Cannot connect to HBase
- ZooKeeper errors
- "Not in running state"

**Diagnosis**:
```bash
# Check ZooKeeper
docker-compose exec zookeeper bash
echo ruok | nc localhost 2181

# Check HBase logs
docker-compose logs hbase-master
docker-compose logs hbase-regionserver
```

**Solutions**:

a) **Verify ZooKeeper is healthy**:
```bash
# Check ZooKeeper status
docker-compose exec zookeeper bash
zkServer.sh status
```

b) **Check HDFS is ready**:
```bash
# HBase needs HDFS
docker-compose exec namenode hadoop fs -ls /hbase
```

c) **Restart HBase cluster**:
```bash
docker-compose restart hbase-master hbase-regionserver
```

### 8. File Permission Errors

**Symptom**: "Permission denied" when accessing files

**Error**:
```
org.apache.hadoop.security.AccessControlException: Permission denied
```

**Solution**:
```bash
# Check file permissions
docker-compose exec namenode bash
hadoop fs -ls -la /path/to/file

# Change permissions if needed
hadoop fs -chmod -R 777 /path/to/directory
hadoop fs -chown -R hadoop:hadoop /path/to/directory
```

### 9. MapReduce Job Failures

**Symptom**: Jobs fail with no clear error
- Task failures
- Hung jobs

**Diagnosis**:
```bash
# Check job logs
docker-compose exec namenode bash
yarn logs -applicationId <app_id>

# Check ResourceManager logs
docker-compose logs resourcemanager | grep -i error
```

**Solutions**:

a) **Increase memory allocation**:
```bash
# In mapred-site.xml increase:
# - mapreduce.map.memory.mb
# - mapreduce.reduce.memory.mb
# - mapreduce.map.java.opts
# - mapreduce.reduce.java.opts
```

b) **Check input data format**:
```bash
# Verify input files exist and are readable
hadoop fs -cat /input/file.txt | head -10
```

c) **Enable debugging**:
```bash
# Submit job with debug enabled
yarn jar ... -Dmapreduce.task.debug=true
```

### 10. High Disk I/O / Slow Performance

**Symptom**: Slow queries, high CPU/disk usage

**Diagnosis**:
```bash
# Check resource usage
docker stats

# Check disk I/O
docker-compose exec namenode bash
iostat -x 1
```

**Solutions**:

a) **Enable compression**:
```bash
# In configuration files, enable compression
hadoop fs -cat /etc/hadoop/conf/mapred-site.xml | grep compress
```

b) **Optimize block size**:
```bash
# Adjust dfs.blocksize in hdfs-site.xml
```

c) **Limit concurrent tasks**:
```bash
# In mapred-site.xml
# - mapreduce.job.maps
# - mapreduce.job.reduces
```

## Debugging Techniques

### 1. View Container Logs

```bash
# Real-time logs
docker-compose logs -f <service_name>

# Last N lines
docker-compose logs <service_name> | tail -50

# Specific time range
docker-compose logs --since 2024-11-15T10:30:00
```

### 2. Connect to Container Shell

```bash
# Interactive bash session
docker-compose exec <service_name> bash

# Run single command
docker-compose exec <service_name> command args
```

### 3. Check Network Connectivity

```bash
# From one container to another
docker-compose exec namenode nc -zv hive-server 10000

# Test DNS resolution
docker-compose exec namenode nslookup mariadb
```

### 4. Inspect Configuration

```bash
# View XML configuration
docker-compose exec namenode cat /etc/hadoop/conf/core-site.xml

# View environment variables
docker-compose exec namenode env | grep JAVA_HOME
```

### 5. Monitor Resource Usage

```bash
# Check Docker resource usage
docker stats

# Check inside container
docker-compose exec namenode bash
free -h
df -h
top -b -n 1
```

## Performance Profiling

### 1. Hadoop Job Counters

```bash
# Get job details
yarn application -status <app_id>

# Get detailed counters
mapred job -counter <job_id> mapreduce.job.counter_name
```

### 2. Profile Map/Reduce Tasks

```bash
# Enable task profiling
-Dmapreduce.task.profile=true

# View profile output
hadoop fs -cat /output/_task_profiles/*
```

### 3. Network Profiling

```bash
# Monitor network I/O
docker-compose exec namenode bash
iftop -i eth0

# Check packet stats
netstat -i
```

## Recovery Procedures

### 1. Full Cluster Reset

```bash
# Stop all services
bash scripts/stop.sh

# Clean all data
bash scripts/cleanup.sh

# Start fresh
bash scripts/start.sh
```

### 2. Recover from Corrupted HDFS

```bash
# Backup current namenode metadata
docker cp namenode:/hadoop/dfs/name ./backup/

# Restart namenode
docker-compose restart namenode

# Check logs
docker-compose logs namenode
```

### 3. Restore from Backup

```bash
# If you have a backup of data
hadoop fs -cp /backup/data/* /data/
```

## Common Error Messages and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot assign requested address` | Port conflict | Check port availability |
| `Connection refused` | Service not running | Start service, check logs |
| `No space left on device` | Disk full | Clean files or increase disk |
| `java.io.IOException: Broken pipe` | Network issue | Check network, restart service |
| `UnknownHostException` | DNS resolution failure | Check container names |
| `Permission denied` | Access rights | Change permissions with chmod |
| `Timed out` | Service slow/unresponsive | Increase timeout, check resources |
| `Class not found` | Missing JAR | Check classpath and libraries |

## Getting Help

### Useful Resources

1. **Logs**: Always check `docker-compose logs <service>`
2. **Web UIs**: Visual inspection of status
3. **Command-line tools**: hadoop, yarn, hive commands
4. **Official docs**: Apache Hadoop, Hive, HBase documentation

### Effective Debugging Steps

1. Identify which service is failing
2. Check service logs
3. Verify network connectivity
4. Check resource allocation
5. Verify configuration files
6. Restart service and monitor
7. Check application-level logs
