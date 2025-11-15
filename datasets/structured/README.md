# Structured Data Dataset

CSV files containing relational data for Hive SQL exercises.

## Files

- **employees.csv** - Employee records
- **sales.csv** - Sales transaction records
- **customers.csv** - Customer information
- **products.csv** - Product catalog

## Schema

### employees.csv
```
employee_id, name, department, salary, age, hire_date
```

### sales.csv
```
order_id, product_id, customer_id, employee_id, quantity, amount, order_date
```

### customers.csv
```
customer_id, name, email, region, join_date, total_spend
```

### products.csv
```
product_id, product_name, category, price, stock_quantity
```

## Usage

To load CSV data into Hive:

```sql
CREATE TABLE employees (
  employee_id INT,
  name STRING,
  department STRING,
  salary DOUBLE,
  age INT,
  hire_date STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '/datasets/structured/employees.csv'
INTO TABLE employees;
```
