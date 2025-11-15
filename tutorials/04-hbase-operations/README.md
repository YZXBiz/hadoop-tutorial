# Tutorial 04: HBase Operations

Learn NoSQL data operations with Apache HBase.

## Learning Objectives

- Connect to HBase shell
- Create tables with column families
- Insert and retrieve data
- Scan table contents
- Delete rows and columns
- Understand HBase data model

## Prerequisites

- HBase Master and RegionServer running
- ZooKeeper operational
- HBase Web UI accessible at http://localhost:16010

## HBase Data Model

### Concepts
- **Table**: Like a relational table but schema-less
- **Row Key**: Unique identifier for each row
- **Column Family**: Groups of related columns
- **Column Qualifier**: Individual column within a family
- **Cell**: Value at intersection of row and column
- **Timestamp**: Version control for each cell

### Table Design
```
TableName: users

Row Key           | personal:name  | personal:age | contact:email
user123           | John Doe       | 30           | john@example.com
user456           | Jane Smith     | 28           | jane@example.com
```

## Connecting to HBase

```bash
# Connect to HBase shell
docker-compose exec hbase-master hbase shell

# Or run commands directly
docker-compose exec hbase-master hbase
```

## Basic Commands

### Create a Table

```bash
# Basic table creation
create 'users', 'personal', 'contact'

# List tables
list

# Describe table structure
describe 'users'
```

### Data Operations

#### Insert (Put) Data

```bash
# Insert single cell
put 'users', 'user123', 'personal:name', 'John Doe'
put 'users', 'user123', 'personal:age', '30'
put 'users', 'user123', 'contact:email', 'john@example.com'

# Insert multiple cells for the same row
put 'users', 'user456', 'personal:name', 'Jane Smith'
put 'users', 'user456', 'personal:age', '28'
put 'users', 'user456', 'contact:email', 'jane@example.com'
```

#### Retrieve (Get) Data

```bash
# Get entire row
get 'users', 'user123'

# Get specific column family
get 'users', 'user123', 'personal'

# Get specific cell
get 'users', 'user123', 'personal:name'

# Get with timestamp
get 'users', 'user123', {TIMERANGE => [1000, 2000]}
```

#### Scan Operations

```bash
# Scan entire table
scan 'users'

# Scan with limit
scan 'users', {LIMIT => 10}

# Scan specific column family
scan 'users', {COLUMNS => 'personal'}

# Scan with row key prefix
scan 'users', {STARTROW => 'user1', STOPROW => 'user9'}

# Scan with column limit
scan 'users', {COLUMNS => 'personal:name'}
```

#### Update Data

```bash
# Update is just another put with same row key
put 'users', 'user123', 'personal:age', '31'
```

#### Delete Data

```bash
# Delete specific cell
delete 'users', 'user123', 'contact:email'

# Delete entire row
deleteall 'users', 'user123'

# Delete all cells of a column family
delete 'users', 'user456', 'personal'
```

#### Truncate Table

```bash
# Remove all data but keep schema
truncate 'users'
```

### Modify Table

```bash
# Disable table before modification
disable 'users'

# Alter table structure
alter 'users', {NAME => 'newFamily'}

# Enable table
enable 'users'

# Drop table
drop 'users'
```

## Complete Example

```bash
# Create table
create 'products', 'info', 'inventory', 'pricing'

# Add products
put 'products', 'prod001', 'info:name', 'Laptop'
put 'products', 'prod001', 'info:description', 'High-performance laptop'
put 'products', 'prod001', 'inventory:stock', '45'
put 'products', 'prod001', 'pricing:price', '1299.99'
put 'products', 'prod001', 'pricing:currency', 'USD'

put 'products', 'prod002', 'info:name', 'Mouse'
put 'products', 'prod002', 'info:description', 'Wireless mouse'
put 'products', 'prod002', 'inventory:stock', '320'
put 'products', 'prod002', 'pricing:price', '29.99'
put 'products', 'prod002', 'pricing:currency', 'USD'

# Retrieve data
get 'products', 'prod001'

# Scan all products
scan 'products'

# Update stock
put 'products', 'prod001', 'inventory:stock', '44'

# Count rows
count 'products'
```

## Advanced Operations

### Versioning

```bash
# Get all versions of a cell
get 'users', 'user123', {COLUMN => 'personal:age', VERSIONS => 5}

# Get specific version (timestamp)
get 'users', 'user123', {COLUMN => 'personal:age', TIMESTAMP => 1234567890}
```

### Filters

```bash
# Get rows with specific condition
scan 'users', {FILTER => "ValueFilter(=, 'binary:30')"}

# Filter by row key pattern
scan 'users', {FILTER => "RowFilter(=, 'regexstring:user[0-9]+')"}
```

### Increment

```bash
# Increment numeric value
incr 'products', 'prod001', 'inventory:stock', -1
```

## Exercises

1. Create a "customers" table with column families "profile", "contact", "account"
2. Insert at least 5 customer records
3. Retrieve a specific customer's profile
4. Scan and display all customers from a certain region
5. Update a customer's email address
6. Delete a customer record

## Monitoring

### HBase Web UI
- Open http://localhost:16010
- Check table list and statistics
- Monitor region servers
- View logs

### Command Line
```bash
# Check table status
status

# Count rows in table
count 'users'

# Get table size
size 'users'
```

## Best Practices

1. **Row Key Design**: Use salt to distribute load evenly
   - Instead of: `2024-11-15-user123`
   - Use: `a-2024-11-15-user123`, `b-2024-11-15-user123`

2. **Column Family Design**: Group related data
   - Keep number of column families small (1-3)
   - Avoid frequently-updated columns in same family

3. **Data Types**: HBase stores everything as bytes
   - Use consistent serialization format
   - Consider using Avro or Protocol Buffers

4. **Compression**: Enable for large column families
   - Reduces storage and network I/O
   - Trade off CPU for storage

## Troubleshooting

**Cannot connect to HBase**: Check ZooKeeper and Master services
```bash
docker-compose logs zookeeper
docker-compose logs hbase-master
```

**Table not found**: Verify table name with `list` command

**No data returned**: Check row key spelling and scan entire table first
