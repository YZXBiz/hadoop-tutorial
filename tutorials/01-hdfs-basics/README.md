# Tutorial 01: HDFS Basics

**Duration:** 30-45 minutes
**Difficulty:** Beginner

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What HDFS is** and why we need distributed file systems
- **How files are stored** across multiple machines (block splitting & replication)
- **Why HDFS is different** from your local file system
- **How to interact with HDFS** using command-line tools

**Real-world relevance:** Companies like Netflix, Uber, and Airbnb use HDFS to store petabytes of data across thousands of machines. Understanding HDFS is fundamental to working with big data.

---

## Conceptual Overview: What is HDFS?

### The Problem HDFS Solves

Imagine you have a 1TB video file. Traditional approaches have problems:
- **Single machine storage:** What if your hard drive is only 500GB?
- **Reliability:** What if that one hard drive fails? You lose everything.
- **Performance:** Reading 1TB from a single disk is slow.

### The HDFS Solution

HDFS (Hadoop Distributed File System) solves this by:
1. **Splitting large files** into blocks (default: 128MB each)
2. **Distributing blocks** across many machines (DataNodes)
3. **Replicating each block** (usually 3 copies) for fault tolerance
4. **Tracking everything** with a master server (NameNode)

### Architecture Diagram

```
                    ┌─────────────────────────────────┐
                    │       NameNode (Master)         │
                    │  Stores: File → Block mapping   │
                    │          Block locations        │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
          ┌─────────▼────────┐         ┌─────────▼────────┐
          │  DataNode 1      │         │  DataNode 2      │
          │                  │         │                  │
          │  Block A (copy1) │         │  Block A (copy2) │
          │  Block B (copy1) │         │  Block B (copy2) │
          │  Block C (copy2) │         │  Block C (copy1) │
          └──────────────────┘         └──────────────────┘

When you upload shakespeare.txt (5MB):
  → HDFS splits it: Not needed (< 128MB), stored as 1 block
  → Replicates it: 2 copies (one per DataNode)
  → NameNode tracks: "shakespeare.txt = Block_12345, locations: DN1, DN2"
```

### Key Concepts

| Concept | What It Means | Why It Matters |
|---------|---------------|----------------|
| **NameNode** | Master server that knows where everything is stored | Single point of coordination (without it, cluster can't function) |
| **DataNode** | Worker servers that actually store the data blocks | More DataNodes = more storage capacity |
| **Block** | Chunk of a file (default 128MB) | Large files get split, small files waste space |
| **Replication** | Making copies of blocks on different machines | If one machine dies, data survives |
| **Replication Factor** | Number of copies (default: 3, we use 2) | Higher = more reliable, more space used |

---

## Prerequisites

Before starting, ensure:
```bash
# Check that your cluster is running
docker-compose ps

# You should see these services as "Up":
# - namenode
# - datanode1
# - datanode2
```

If services aren't running:
```bash
cd /Users/jason/Files/Practice/demo-little-things/hadoop-tutorial
docker-compose up -d
```

---

## Hands-On Exercises

### Exercise 1: Connect to the NameNode

**What we're doing:** Opening a terminal inside the NameNode container where Hadoop tools are installed.

```bash
docker-compose exec namenode bash
```

**Expected result:**
```
hadoop@namenode:/opt/hadoop$
```

**What just happened?**
- You're now "inside" the NameNode container
- You have access to Hadoop commands (hadoop, hdfs)
- Your prompt changed to show you're in the container

**To exit later:** Type `exit` and press Enter

---

### Exercise 2: Explore the HDFS Root Directory

**Concept:** HDFS has its own file system, separate from the Linux file system in the container.

```bash
hadoop fs -ls /
```

**Expected output:**
```
Found 2 items
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 10:00 /tmp
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 10:00 /user
```

**What this tells us:**
- `/` is the HDFS root (not the Linux root)
- `drwxr-xr-x` = permissions (d = directory)
- `hadoop` = owner
- Two directories exist: `/tmp` and `/user`

**Try this:**
```bash
# Compare to Linux file system
ls /
# You'll see different directories (etc, usr, bin, etc.)
# This shows HDFS is completely separate!
```

---

### Exercise 3: Create Your First Directory

**Concept:** Just like `mkdir` on Linux, HDFS has its own directory creation.

```bash
# Create a directory for our data
hadoop fs -mkdir /user/hadoop/data

# Verify it was created
hadoop fs -ls /user/hadoop/
```

**Expected output:**
```
Found 1 items
drwxr-xr-x   - hadoop supergroup          0 2025-11-15 10:30 /user/hadoop/data
```

**What happened under the hood:**
1. Your command went to the NameNode
2. NameNode updated its metadata: "Directory `/user/hadoop/data` exists"
3. **No data was written to DataNodes** (directories are just metadata)

**Real-world context:** In production, you'd organize data like:
```
/user/analytics/logs/2025/11/
/user/ml_models/training_data/
/data/raw/clickstream/
```

---

### Exercise 4: Upload a File to HDFS

**Concept:** Moving data from local storage into the distributed file system.

```bash
# Upload Shakespeare text file
hadoop fs -put /datasets/wordcount/shakespeare.txt /user/hadoop/data/

# List the directory
hadoop fs -ls /user/hadoop/data/
```

**Expected output:**
```
Found 1 items
-rw-r--r--   2 hadoop supergroup    5458199 2025-11-15 10:35 /user/hadoop/data/shakespeare.txt
```

**Let's decode this output:**
- `-rw-r--r--` = file permissions (- = file, not directory)
- `2` = **replication factor** (2 copies exist)
- `5458199` = file size in bytes (~5.2MB)
- Timestamp and filename

**What happened under the hood:**

```
Step 1: Client (you) → NameNode
  "I want to upload shakespeare.txt (5.2MB)"

Step 2: NameNode → Client
  "Ok, here's the plan:
   - Create 1 block (file is < 128MB)
   - Store copies on: datanode1, datanode2"

Step 3: Client → DataNode1
  [Sends file data directly]

Step 4: DataNode1 → DataNode2
  [Replicates the block automatically]

Step 5: DataNodes → NameNode
  "Block stored successfully"
```

**Diagram of what's stored:**
```
NameNode Metadata:
  /user/hadoop/data/shakespeare.txt
    → Block ID: blk_1073741825
    → Size: 5,458,199 bytes
    → Locations: [datanode1:9866, datanode2:9866]
    → Replication: 2

DataNode1:            DataNode2:
  blk_1073741825        blk_1073741825
  [full file data]      [full file data]
```

---

### Exercise 5: View File Content

**Concept:** Reading data from HDFS (like `cat` on Linux).

```bash
# View entire file (careful with large files!)
hadoop fs -cat /user/hadoop/data/shakespeare.txt | head -20
```

**Expected output:**
```
THE SONNETS

by William Shakespeare


                     1
  From fairest creatures we desire increase,
  That thereby beauty's rose might never die,
  But as the riper should by time decease,
  His tender heir might bear his memory:
...
```

**What happened:**
1. Command → NameNode: "Where is shakespeare.txt?"
2. NameNode → You: "Block is on datanode1 and datanode2"
3. You → DataNode1: "Send me the data" (picks closest DataNode)
4. Data streams back to you

**Performance note:** In production, HDFS can read from multiple blocks in parallel, making it fast for huge files.

---

### Exercise 6: Check File Details

**Concept:** Understanding how your file is stored.

```bash
# Get detailed statistics
hadoop fs -stat "%n %r %b %o" /user/hadoop/data/shakespeare.txt
```

**Expected output:**
```
shakespeare.txt 2 5458199 128
```

**What this means:**
- `shakespeare.txt` = filename
- `2` = replication factor (2 copies)
- `5458199` = size in bytes
- `128` = block size in MB (even though file uses only 1 block)

**Try this:**
```bash
# Human-readable file size
hadoop fs -du -h /user/hadoop/data/

# Output:
# 5.2 M  10.4 M  /user/hadoop/data/shakespeare.txt
#  ↑      ↑
#  │      └─ Total space used (5.2M × 2 replicas)
#  └─ Actual file size
```

---

### Exercise 7: Copy Within HDFS

**Concept:** Copying files between HDFS directories (no download/upload needed).

```bash
# Create a backup
hadoop fs -cp /user/hadoop/data/shakespeare.txt /user/hadoop/data/shakespeare_backup.txt

# List files
hadoop fs -ls /user/hadoop/data/
```

**Expected output:**
```
Found 2 items
-rw-r--r--   2 hadoop supergroup    5458199 2025-11-15 10:35 /user/hadoop/data/shakespeare.txt
-rw-r--r--   2 hadoop supergroup    5458199 2025-11-15 10:40 /user/hadoop/data/shakespeare_backup.txt
```

**What happened:**
- Data was copied **within HDFS** (no network transfer to your machine)
- New blocks were created and replicated
- Now you have 2 files × 2 replicas = 4 total copies across DataNodes

---

### Exercise 8: Download from HDFS

**Concept:** Moving data from HDFS to local file system.

```bash
# Download to container's local filesystem
hadoop fs -get /user/hadoop/data/shakespeare.txt /tmp/shakespeare_local.txt

# Verify with Linux commands
ls -lh /tmp/shakespeare_local.txt
```

**Expected output:**
```
-rw-r--r-- 1 hadoop hadoop 5.3M Nov 15 10:45 /tmp/shakespeare_local.txt
```

**Important distinction:**
```
HDFS file:     /user/hadoop/data/shakespeare.txt (distributed across cluster)
Local file:    /tmp/shakespeare_local.txt (only on this container)
```

---

### Exercise 9: Delete Files

**Concept:** Removing data from HDFS.

```bash
# Delete the backup
hadoop fs -rm /user/hadoop/data/shakespeare_backup.txt

# Verify it's gone
hadoop fs -ls /user/hadoop/data/
```

**Expected output:**
```
Found 1 items
-rw-r--r--   2 hadoop supergroup    5458199 2025-11-15 10:35 /user/hadoop/data/shakespeare.txt
```

**What happened:**
- NameNode removed the file from its metadata
- DataNodes deleted the actual blocks (may take time)
- Space is reclaimed

**Delete directory:**
```bash
# Delete directory and all contents
hadoop fs -rm -r /user/hadoop/data/

# Recreate for next exercises
hadoop fs -mkdir -p /user/hadoop/data
hadoop fs -put /datasets/wordcount/shakespeare.txt /user/hadoop/data/
```

---

### Exercise 10: Monitor HDFS via Web UI

**Concept:** Visual monitoring of your cluster.

1. **Open your browser:** http://localhost:9870

2. **Explore the Overview tab:**
   - Total configured capacity
   - DFS Used (how much space is used)
   - Live DataNodes (should show 2)

3. **Click "Datanodes" tab:**
   - See both datanode1 and datanode2
   - Check their capacity and usage

4. **Click "Utilities" → "Browse the file system":**
   - Navigate to `/user/hadoop/data/`
   - See your shakespeare.txt file
   - Click on it to see which DataNodes have blocks

**What you're seeing:**
```
┌─────────────────────────────────────┐
│   NameNode Web UI (Port 9870)      │
│                                     │
│  Cluster Summary:                   │
│  ├─ Capacity: 100 GB               │
│  ├─ Used: 10.4 MB (shakespeare×2)  │
│  └─ Live Nodes: 2/2                │
│                                     │
│  DataNode Status:                   │
│  ├─ datanode1: Healthy ✓           │
│  └─ datanode2: Healthy ✓           │
└─────────────────────────────────────┘
```

---

## Understanding the Commands

### Common HDFS Command Patterns

```bash
hadoop fs -<command> <args>
```

| Command | What it does | Similar to |
|---------|-------------|------------|
| `-ls` | List directory contents | `ls` (Linux) |
| `-mkdir` | Create directory | `mkdir` (Linux) |
| `-put` | Upload to HDFS | `cp` (to remote) |
| `-get` | Download from HDFS | `cp` (from remote) |
| `-cat` | View file content | `cat` (Linux) |
| `-cp` | Copy within HDFS | `cp` (Linux) |
| `-mv` | Move/rename in HDFS | `mv` (Linux) |
| `-rm` | Delete | `rm` (Linux) |
| `-du` | Disk usage | `du` (Linux) |
| `-df` | Filesystem info | `df` (Linux) |

**Pro tip:** Most Linux file commands have HDFS equivalents!

---

## Common Issues and Solutions

### Issue 1: "Safe mode is ON"

**Error message:**
```
Cannot create file /user/hadoop/data/file.txt. Name node is in safe mode.
```

**What's happening:** NameNode is in read-only mode (usually on startup).

**Solution:**
```bash
# Check safe mode status
hdfs dfsadmin -safemode get

# Force leave safe mode (development only!)
hdfs dfsadmin -safemode leave
```

---

### Issue 2: "No space left"

**Error message:**
```
Could not write file. No space left on device.
```

**Solution:**
```bash
# Check HDFS capacity
hadoop fs -df -h

# Clean up old files
hadoop fs -rm -r /user/hadoop/old_data/

# Check which files are large
hadoop fs -du -h /user/hadoop/ | sort -h
```

---

### Issue 3: "Permission denied"

**Error message:**
```
Permission denied: user=root, access=WRITE, inode="/user/hadoop":hadoop:supergroup:drwxr-xr-x
```

**Solution:**
```bash
# Change ownership
hadoop fs -chown -R hadoop:hadoop /user/hadoop/

# Or change permissions
hadoop fs -chmod -R 777 /user/hadoop/data/
```

---

## Real-World Applications

### Example 1: Log Storage
```bash
# Companies store daily logs in HDFS
hadoop fs -mkdir -p /logs/webserver/2025/11/15/
hadoop fs -put /var/log/nginx/access.log /logs/webserver/2025/11/15/

# Benefit: Logs are replicated and can survive server failures
```

### Example 2: Data Lake
```bash
# Raw data from various sources
hadoop fs -mkdir -p /datalake/raw/customer_events/
hadoop fs -put customer_clicks.json /datalake/raw/customer_events/

# Processed data
hadoop fs -mkdir -p /datalake/processed/aggregated/
```

### Example 3: ML Training Data
```bash
# Large datasets for machine learning
hadoop fs -put training_images.tar.gz /ml/datasets/imagenet/
# Benefit: Data can be read by multiple compute nodes in parallel
```

---

## Key Takeaways

✅ **HDFS is a distributed file system** that splits files into blocks and replicates them

✅ **NameNode tracks metadata** (where files are), DataNodes store actual data

✅ **Replication provides fault tolerance** (your data survives machine failures)

✅ **HDFS is optimized for large files** (100MB+), not small files

✅ **Commands are similar to Linux** but work across the cluster

---

## Next Steps

**You've mastered HDFS basics!** Now you can:

1. **Move to Tutorial 02** to learn MapReduce and process this data
2. **Experiment more:**
   ```bash
   # Try uploading larger files
   hadoop fs -put /datasets/logs/access_logs.txt /user/hadoop/data/

   # Check replication
   hadoop fs -stat "%r" /user/hadoop/data/access_logs.txt
   ```
3. **Learn more:** Read about HDFS architecture at https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html

---

## Quick Reference Card

```bash
# Connect to cluster
docker-compose exec namenode bash

# Common operations
hadoop fs -ls /                                    # List root
hadoop fs -mkdir -p /path/to/dir                  # Create directory
hadoop fs -put local_file /hdfs/path              # Upload
hadoop fs -get /hdfs/path local_file              # Download
hadoop fs -cat /hdfs/path | head                  # View content
hadoop fs -du -h /path                            # Check size
hadoop fs -rm -r /path                            # Delete

# Monitoring
http://localhost:9870                             # NameNode Web UI
hadoop fs -df -h                                  # Cluster capacity
```

**Exit container:** `exit`
