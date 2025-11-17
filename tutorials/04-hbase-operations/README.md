# Tutorial 04: HBase Operations

**Duration:** 45-60 minutes
**Difficulty:** Intermediate
**Prerequisites:** Complete Tutorials 01-03 (HDFS, MapReduce, Hive)

## What You'll Learn (and Why It Matters)

By the end of this tutorial, you'll understand:
- **What HBase is** and why NoSQL matters for big data
- **Row-oriented vs column-oriented** storage models
- **How HBase differs** from HDFS, Hive, and traditional databases
- **Real-time random access** to massive datasets
- **HBase data model** with row keys, column families, and cells

**Real-world relevance:** Facebook uses HBase to store messages (100+ billion messages). Adobe uses it for analytics. When you need sub-second lookups on petabytes of data, HBase is the answer.

---

## Conceptual Overview: What is HBase?

### The Problem HBase Solves

**Scenario:** You have a user profile service with 1 billion users.

**Option 1: Traditional Database (MySQL)**
```
Problem: Can't scale to billions of rows
         Slow for random reads at this scale
         Expensive to shard horizontally
```

**Option 2: HDFS + Hive**
```
Problem: Great for batch analytics but...
         Every query scans entire dataset
         Takes minutes, not milliseconds
         Can't do real-time lookups
```

**Option 3: HBase (The Solution!)**
```
✓ Billions of rows, no problem
✓ Random access in milliseconds
✓ Horizontally scalable
✓ Runs on top of HDFS
```

---

### HBase vs Other Storage

| Feature | MySQL | Hive | HBase |
|---------|-------|------|-------|
| **Data size** | GB - TB | TB - PB | TB - PB |
| **Access pattern** | OLTP (transactions) | Batch scans | Random read/write |
| **Latency** | Milliseconds | Seconds - Minutes | Milliseconds |
| **Schema** | Fixed (SQL) | Schema-on-read | Column families |
| **Consistency** | ACID | Eventual | Strong (row-level) |
| **Best for** | Transactions | Analytics | Real-time lookups |

**When to use HBase:**
- ✅ Billions of rows with fast random access
- ✅ Time-series data (metrics, logs)
- ✅ Real-time analytics
- ✅ Key-value lookups at scale
- ✅ Variable schema (different rows have different columns)

**When NOT to use HBase:**
- ❌ Small datasets (< 100GB)
- ❌ Complex JOINs (use Hive instead)
- ❌ Full table scans (use Hive instead)
- ❌ Multi-row transactions

---

### HBase Architecture

```
┌─────────────────────────────────────────────────┐
│           HBase Master                          │
│   - Region assignment                           │
│   - Load balancing                              │
│   - Schema changes                              │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼──────────┐      ┌──────▼─────────┐
│ RegionServer │      │ RegionServer   │
│              │      │                │
│ Region 1     │      │ Region 3       │
│ (rows 0-500k)│      │ (rows 500k-1M) │
│              │      │                │
│ Region 2     │      │ Region 4       │
│ (rows 1M-1.5M)│     │ (rows 1.5M-2M) │
└───┬──────────┘      └──────┬─────────┘
    │                        │
    └────────┬───────────────┘
             │
    ┌────────▼────────┐
    │     HDFS        │
    │  (Data storage) │
    └─────────────────┘

┌──────────────┐
│  ZooKeeper   │
│ (Coordinates │
│   cluster)   │
└──────────────┘
```

**Key components:**
- **HBase Master**: Manages regions, load balancing
- **RegionServer**: Serves data for specific row ranges
- **Region**: Chunk of table (horizontal partition)
- **HDFS**: Persistent storage backend
- **ZooKeeper**: Cluster coordination

---

## HBase Data Model

### Conceptual Model

Think of HBase as a **sparse, distributed, multi-dimensional sorted map**:

```
Table: users
Row Key         | personal:name    | personal:age | contact:email          | contact:phone
----------------|------------------|--------------|------------------------|---------------
user001         | Alice Smith      | 28           | alice@example.com      | 555-1234
user002         | Bob Jones        | 35           | bob@example.com        | (null)
user003         | Carol White      | (null)       | carol@example.com      | 555-5678

Key insights:
- Each row has unique Row Key (like primary key)
- Columns grouped into families (personal, contact)
- Cells can be null (sparse storage)
- Sorted by Row Key
```

### Physical Storage

**How it's actually stored in HDFS:**

```
Row: user001
  Column Family: personal
    personal:name → "Alice Smith" @ timestamp 1700000000
    personal:age  → "28"          @ timestamp 1700000001
  Column Family: contact
    contact:email → "alice@ex..."  @ timestamp 1700000002
    contact:phone → "555-1234"     @ timestamp 1700000003

Every cell has:
  - Value
  - Timestamp (version)
  - Row key + Column family + Column qualifier
```

---

### Key Concepts

| Concept | What It Means | Example |
|---------|---------------|---------|
| **Row Key** | Unique identifier, determines sort order | "user001", "2025-11-15:event123" |
| **Column Family** | Group of related columns (defined at table creation) | "personal", "contact", "metrics" |
| **Column Qualifier** | Specific column within a family (dynamic) | "name", "email", "click_count" |
| **Cell** | Intersection of row + column + timestamp | Value at user001:personal:name |
| **Timestamp** | Version of cell (automatic or manual) | 1700000000 (Unix epoch ms) |
| **Version** | HBase keeps multiple versions of cells | Last 3 versions by default |

---

## Hands-On: Working with HBase

### Exercise 1: Connect to HBase Shell

**Start HBase shell:**
```bash
docker-compose exec hbase-master hbase shell
```

**Expected output:**
```
HBase Shell
Use "help" to get list of supported commands.
Use "exit" to quit this interactive shell.

hbase:001:0>
```

**What just happened:**
- Connected to HBase Master
- Shell uses Ruby syntax
- Ready for commands

**Check cluster status:**
```ruby
status
```

**Expected output:**
```
1 active master, 0 backup masters, 1 servers, 0 dead, 1.0000 average load
Aggregate load: 1, regions: 1
```

---

### Exercise 2: Create Your First Table

**Create a users table:**
```ruby
create 'users', 'personal', 'contact'
```

**Expected output:**
```
Created table users
Took 2.3456 seconds
```

**What this command means:**
```ruby
create 'users',      # Table name
       'personal',   # Column family 1
       'contact'     # Column family 2
```

**Important:** Column families must be defined at table creation. Columns within families are dynamic.

**Verify table creation:**
```ruby
list
```

**Expected output:**
```
TABLE
users
1 row(s)
Took 0.0123 seconds
```

**See table structure:**
```ruby
describe 'users'
```

**Expected output:**
```
Table users is ENABLED
users
COLUMN FAMILIES DESCRIPTION
{NAME => 'contact', BLOOMFILTER => 'ROW', VERSIONS => '1', ...}
{NAME => 'personal', BLOOMFILTER => 'ROW', VERSIONS => '1', ...}
2 row(s)
```

---

### Exercise 3: Insert Data (PUT)

**Insert a user:**
```ruby
put 'users', 'user001', 'personal:name', 'Alice Smith'
put 'users', 'user001', 'personal:age', '28'
put 'users', 'user001', 'contact:email', 'alice@example.com'
put 'users', 'user001', 'contact:phone', '555-1234'
```

**Expected output (per command):**
```
Took 0.0234 seconds
```

**Command breakdown:**
```ruby
put 'users',           # Table name
    'user001',         # Row key
    'personal:name',   # Column family:qualifier
    'Alice Smith'      # Value
```

**What happened under the hood:**
1. HBase Master routes to correct RegionServer
2. RegionServer writes to Write-Ahead Log (WAL) for durability
3. Data stored in MemStore (in-memory)
4. Eventually flushed to HFiles in HDFS

**Insert more users:**
```ruby
put 'users', 'user002', 'personal:name', 'Bob Jones'
put 'users', 'user002', 'personal:age', '35'
put 'users', 'user002', 'contact:email', 'bob@example.com'

put 'users', 'user003', 'personal:name', 'Carol White'
put 'users', 'user003', 'contact:email', 'carol@example.com'
put 'users', 'user003', 'contact:phone', '555-5678'
```

---

### Exercise 4: Retrieve Data (GET)

**Get entire row:**
```ruby
get 'users', 'user001'
```

**Expected output:**
```
COLUMN                        CELL
 contact:email                timestamp=1700000002, value=alice@example.com
 contact:phone                timestamp=1700000003, value=555-1234
 personal:age                 timestamp=1700000001, value=28
 personal:name                timestamp=1700000000, value=Alice Smith
4 row(s)
Took 0.0123 seconds
```

**What this shows:**
- All columns for row 'user001'
- Timestamp when each cell was written
- Values for each column

**Get specific column family:**
```ruby
get 'users', 'user001', 'personal'
```

**Expected output:**
```
COLUMN                        CELL
 personal:age                 timestamp=1700000001, value=28
 personal:name                timestamp=1700000000, value=Alice Smith
2 row(s)
```

**Get specific cell:**
```ruby
get 'users', 'user001', 'personal:name'
```

**Expected output:**
```
COLUMN                        CELL
 personal:name                timestamp=1700000000, value=Alice Smith
1 row(s)
```

---

### Exercise 5: Scan Table

**Scan all rows:**
```ruby
scan 'users'
```

**Expected output:**
```
ROW                          COLUMN+CELL
 user001                     column=contact:email, timestamp=1700000002, value=alice@example.com
 user001                     column=contact:phone, timestamp=1700000003, value=555-1234
 user001                     column=personal:age, timestamp=1700000001, value=28
 user001                     column=personal:name, timestamp=1700000000, value=Alice Smith
 user002                     column=contact:email, timestamp=1700000010, value=bob@example.com
 user002                     column=personal:age, timestamp=1700000009, value=35
 user002                     column=personal:name, timestamp=1700000008, value=Bob Jones
 user003                     column=contact:email, timestamp=1700000020, value=carol@example.com
 user003                     column=contact:phone, timestamp=1700000021, value=555-5678
 user003                     column=personal:name, timestamp=1700000019, value=Carol White
3 row(s)
Took 0.0456 seconds
```

**Scan with LIMIT:**
```ruby
scan 'users', {LIMIT => 2}
```

**Expected output:**
```
ROW                          COLUMN+CELL
 user001                     column=contact:email, ...
 user001                     column=contact:phone, ...
 user001                     column=personal:age, ...
 user001                     column=personal:name, ...
 user002                     column=contact:email, ...
 user002                     column=personal:age, ...
 user002                     column=personal:name, ...
2 row(s)
```

**Scan specific column family:**
```ruby
scan 'users', {COLUMNS => 'personal'}
```

**Scan with row key range:**
```ruby
scan 'users', {STARTROW => 'user001', STOPROW => 'user003'}
```

**Expected output:** Returns user001 and user002 (STOPROW is exclusive)

---

### Exercise 6: Update Data

**Update is just another PUT:**
```ruby
put 'users', 'user001', 'personal:age', '29'
```

**What happened:**
- HBase created a NEW version of the cell
- Old version still exists (with older timestamp)
- By default, GET returns latest version

**Verify update:**
```ruby
get 'users', 'user001', 'personal:age'
```

**Expected output:**
```
COLUMN                        CELL
 personal:age                 timestamp=1700001000, value=29
1 row(s)
```

**See all versions:**
```ruby
get 'users', 'user001', {COLUMN => 'personal:age', VERSIONS => 5}
```

**Expected output:**
```
COLUMN                        CELL
 personal:age                 timestamp=1700001000, value=29
 personal:age                 timestamp=1700000001, value=28
2 row(s)
```

---

### Exercise 7: Delete Data

**Delete specific cell:**
```ruby
delete 'users', 'user001', 'contact:phone'
```

**Expected output:**
```
Took 0.0123 seconds
```

**Verify deletion:**
```ruby
get 'users', 'user001'
```

**Output:** contact:phone is gone

**Delete entire row:**
```ruby
deleteall 'users', 'user003'
```

**Verify:**
```ruby
scan 'users'
```

**Output:** user003 is completely removed

---

### Exercise 8: Counting Rows

**Count all rows:**
```ruby
count 'users'
```

**Expected output:**
```
2 row(s)
Took 0.0456 seconds
```

**Why 2?** We deleted user003

---

### Exercise 9: Advanced Table - Product Catalog

**Create products table:**
```ruby
create 'products', 'info', 'inventory', 'pricing'
```

**Insert product data:**
```ruby
put 'products', 'prod001', 'info:name', 'Laptop'
put 'products', 'prod001', 'info:description', 'High-performance laptop'
put 'products', 'prod001', 'info:category', 'Electronics'
put 'products', 'prod001', 'inventory:stock', '45'
put 'products', 'prod001', 'inventory:warehouse', 'WH-01'
put 'products', 'prod001', 'pricing:price', '1299.99'
put 'products', 'prod001', 'pricing:currency', 'USD'

put 'products', 'prod002', 'info:name', 'Mouse'
put 'products', 'prod002', 'info:description', 'Wireless mouse'
put 'products', 'prod002', 'info:category', 'Electronics'
put 'products', 'prod002', 'inventory:stock', '320'
put 'products', 'prod002', 'inventory:warehouse', 'WH-02'
put 'products', 'prod002', 'pricing:price', '29.99'
put 'products', 'prod002', 'pricing:currency', 'USD'
```

**Query a product:**
```ruby
get 'products', 'prod001'
```

**Expected output:**
```
COLUMN                        CELL
 info:category                timestamp=..., value=Electronics
 info:description             timestamp=..., value=High-performance laptop
 info:name                    timestamp=..., value=Laptop
 inventory:stock              timestamp=..., value=45
 inventory:warehouse          timestamp=..., value=WH-01
 pricing:currency             timestamp=..., value=USD
 pricing:price                timestamp=..., value=1299.99
7 row(s)
```

---

## Advanced Operations

### Filters

**Scan with value filter:**
```ruby
scan 'products', {FILTER => "ValueFilter(=, 'binary:Electronics')"}
```

**Expected output:** Only products in Electronics category

**Scan with row key prefix:**
```ruby
scan 'products', {FILTER => "PrefixFilter('prod00')"}
```

---

### Increment Counter

**Create counter table:**
```ruby
create 'page_views', 'stats'
put 'page_views', 'page1', 'stats:count', '0'
```

**Increment view count:**
```ruby
incr 'page_views', 'page1', 'stats:count', 1
```

**Expected output:**
```
COUNTER VALUE = 1
```

**Increment again:**
```ruby
incr 'page_views', 'page1', 'stats:count', 5
```

**Expected output:**
```
COUNTER VALUE = 6
```

---

### Truncate Table

**Remove all data but keep schema:**
```ruby
truncate 'users'
```

**What happens:**
1. Table is disabled
2. Table is dropped
3. Table is recreated with same schema
4. All data is gone

---

## Table Management

### Disable/Enable Table

**Disable table (required before modifications):**
```ruby
disable 'users'
```

**Add new column family:**
```ruby
alter 'users', {NAME => 'metadata'}
```

**Enable table:**
```ruby
enable 'users'
```

**Verify change:**
```ruby
describe 'users'
```

---

### Drop Table

**Drop table:**
```ruby
disable 'users'
drop 'users'
```

**Verify:**
```ruby
list
```

---

## Row Key Design (Critical!)

### Good vs Bad Row Keys

**❌ BAD: Sequential keys**
```
user0001
user0002
user0003
...

Problem: All writes go to same RegionServer (hotspot)
```

**✅ GOOD: Salted keys**
```
a-user0001
b-user0002
c-user0003
...

Benefit: Writes distributed across RegionServers
```

**✅ GOOD: Reversed timestamp**
```
9999999999999-event001  (for most recent first)
2025-11-15-event001     (for chronological)

Benefit: Recent data together, range scans efficient
```

---

## Real-World Use Cases

### Use Case 1: Time-Series Data

**Create metrics table:**
```ruby
create 'metrics', 'data'

# Row key: sensor_id + reversed_timestamp
put 'metrics', 'sensor001:9999999999999', 'data:temperature', '22.5'
put 'metrics', 'sensor001:9999999999998', 'data:temperature', '22.7'
put 'metrics', 'sensor001:9999999999997', 'data:temperature', '22.4'
```

**Query recent metrics:**
```ruby
scan 'metrics', {STARTROW => 'sensor001:', LIMIT => 10}
```

---

### Use Case 2: User Sessions

**Create sessions table:**
```ruby
create 'sessions', 'info'

put 'sessions', 'session123', 'info:user_id', 'user456'
put 'sessions', 'session123', 'info:login_time', '2025-11-15T10:30:00'
put 'sessions', 'session123', 'info:ip_address', '192.168.1.100'
```

---

### Use Case 3: Message Store (Facebook-style)

**Create messages table:**
```ruby
create 'messages', 'content', 'metadata'

put 'messages', 'user001:msg001', 'content:text', 'Hello!'
put 'messages', 'user001:msg001', 'metadata:timestamp', '1700000000'
put 'messages', 'user001:msg001', 'metadata:sender', 'user002'
```

---

## Monitoring HBase

### Web UI

**Open HBase Master Web UI:**
```
http://localhost:16010
```

**What you'll see:**
- Table list and regions
- RegionServer status
- System tasks and logs
- Cluster metrics

---

## Common Issues

### Issue 1: Table not found

**Error:**
```
ERROR: Unknown table users!
```

**Solution:**
```ruby
list  # Check table name spelling
create 'users', 'cf1' if needed
```

---

### Issue 2: Can't modify enabled table

**Error:**
```
ERROR: Table users is enabled. Disable it first.
```

**Solution:**
```ruby
disable 'users'
alter 'users', ...
enable 'users'
```

---

## Key Takeaways

✅ **HBase is for random access** at massive scale

✅ **Column families** are fixed, columns are dynamic

✅ **Row key design is critical** for performance

✅ **Versioning is automatic** - cells have timestamps

✅ **Strong consistency** at row level

✅ **Built on HDFS** for durability and replication

---

## Next Steps

**You've mastered HBase basics!** Now you can:

1. **Move to Tutorial 05** to learn Pig (data flow scripting)
2. **Practice more:**
   - Design row keys for different use cases
   - Try filters and advanced scans
   - Experiment with versioning
3. **Read more:** [HBase Reference Guide](https://hbase.apache.org/book.html)

---

## Quick Reference

```ruby
# Connect
docker-compose exec hbase-master hbase shell

# Tables
list
create 'table', 'cf1', 'cf2'
describe 'table'
disable 'table'
drop 'table'

# Data operations
put 'table', 'row1', 'cf:col', 'value'
get 'table', 'row1'
scan 'table'
scan 'table', {LIMIT => 10}
delete 'table', 'row1', 'cf:col'
deleteall 'table', 'row1'

# Utilities
count 'table'
truncate 'table'
status

# Monitoring
http://localhost:16010  # HBase Master Web UI

# Exit
exit
```
