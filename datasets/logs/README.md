# Log Files Dataset

Sample web server and application logs for data processing exercises.

## Files

- **access_logs.txt** - Apache/Nginx style access logs
- **server_logs.txt** - Application server logs
- **error_logs.txt** - Error and exception logs

## Usage

These logs are useful for:
- Learning log analysis with Hadoop
- Practicing data filtering and transformation
- Building analytics pipelines
- Understanding real-world data processing scenarios

## Log Format

### Access Logs
```
IP - - [DATE] "METHOD PATH HTTP/VERSION" STATUS SIZE REFERER "USER_AGENT"
```

Example:
```
192.168.1.100 - - [15/Nov/2024:10:30:45 +0000] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
```

### Application Logs
```
[TIMESTAMP] [LEVEL] [MODULE] MESSAGE
```

Example:
```
2024-11-15 10:30:45.123 [INFO] [UserService] User login successful: user_id=12345
```
