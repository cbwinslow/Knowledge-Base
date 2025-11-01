# AWS MCP Server

Model Context Protocol server for AWS service integration.

## Overview

This MCP server provides access to AWS services including EC2, S3, Lambda, RDS, CloudWatch, and ECS. It enables AI agents to query and interact with AWS resources.

## Features

### Supported Services

- **EC2**: List and describe instances
- **S3**: List buckets, get/put objects
- **Lambda**: List and invoke functions
- **RDS**: List database instances
- **CloudWatch**: Query metrics and logs
- **ECS**: List clusters and services

### Capabilities

- ✅ Tools - Execute AWS operations
- ✅ Resources - Access AWS resource information
- ✅ Prompts - Pre-configured AWS operation prompts

## Installation

```bash
cd mcp_servers/aws
pip install -r requirements.txt
```

## Configuration

### AWS Credentials

The server supports multiple authentication methods:

1. **Environment Variables:**
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

2. **AWS Profile:**
```bash
export AWS_PROFILE=your_profile
```

3. **IAM Role** (when running on EC2/ECS/Lambda)

### Server Configuration

Create `config.json` with your settings:

```json
{
  "default_region": "us-east-1",
  "services": {
    "ec2": { "enabled": true },
    "s3": { "enabled": true },
    "lambda": { "enabled": true },
    "rds": { "enabled": true },
    "cloudwatch": { "enabled": true },
    "ecs": { "enabled": true }
  }
}
```

## Usage

### Starting the Server

```bash
python server.py
```

### With Claude Desktop

Add to your Claude Desktop config:

```json
{
  "mcpServers": {
    "aws": {
      "command": "python",
      "args": ["/path/to/mcp_servers/aws/server.py"],
      "env": {
        "AWS_PROFILE": "your-profile"
      }
    }
  }
}
```

## Available Tools

### EC2 Operations

**List Instances**
```python
aws_ec2_list_instances(
    region="us-east-1",
    filters={
        "instance-state-name": ["running"],
        "tag:Environment": ["production"]
    }
)
```

### S3 Operations

**List Buckets**
```python
aws_s3_list_buckets()
```

**Get Object**
```python
aws_s3_get_object(
    bucket="my-bucket",
    key="path/to/object.json"
)
```

### Lambda Operations

**List Functions**
```python
aws_lambda_list_functions(region="us-east-1")
```

**Invoke Function**
```python
aws_lambda_invoke(
    function_name="my-function",
    payload={"key": "value"}
)
```

### RDS Operations

**List Database Instances**
```python
aws_rds_list_instances(region="us-east-1")
```

### CloudWatch Operations

**Get Metrics**
```python
aws_cloudwatch_get_metrics(
    namespace="AWS/EC2",
    metric_name="CPUUtilization",
    dimensions=[
        {"Name": "InstanceId", "Value": "i-1234567890abcdef0"}
    ]
)
```

### ECS Operations

**List Clusters**
```python
aws_ecs_list_clusters(region="us-east-1")
```

**List Services**
```python
aws_ecs_list_services(cluster="my-cluster")
```

## Resources

Access AWS resources through URIs:

- `aws://ec2/instances` - EC2 instances
- `aws://s3/buckets` - S3 buckets
- `aws://lambda/functions` - Lambda functions
- `aws://rds/instances` - RDS databases

## Security

### Best Practices

1. **Least Privilege**: Use IAM roles with minimal required permissions
2. **Credentials**: Never hardcode credentials, use environment variables or IAM roles
3. **Audit**: Enable CloudTrail logging for all API calls
4. **Encryption**: Use encrypted credentials storage
5. **Network**: Restrict network access to the MCP server

### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "s3:ListBuckets",
        "s3:GetObject",
        "lambda:ListFunctions",
        "lambda:InvokeFunction",
        "rds:DescribeDBInstances",
        "cloudwatch:GetMetricData",
        "ecs:ListClusters",
        "ecs:ListServices"
      ],
      "Resource": "*"
    }
  ]
}
```

## Error Handling

The server provides detailed error messages:

- **Authentication Errors**: Invalid credentials or permissions
- **API Errors**: AWS service errors with specific error codes
- **Validation Errors**: Invalid parameters or configurations

## Monitoring

### Logging

Logs are written to stdout in JSON format:

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "INFO",
  "message": "AWS API call",
  "service": "ec2",
  "operation": "describe_instances",
  "duration_ms": 150
}
```

### Metrics

Track server metrics:
- API call count by service
- Response times
- Error rates
- Authentication failures

## Troubleshooting

### Connection Issues

1. Check AWS credentials are valid
2. Verify IAM permissions
3. Check network connectivity to AWS
4. Verify region configuration

### Performance Issues

1. Use pagination for large result sets
2. Cache frequently accessed data
3. Use regional endpoints
4. Implement request throttling

## Development

### Running Tests

```bash
pytest tests/
```

### Adding New Services

1. Add service configuration to `config.json`
2. Implement service methods in `services/`
3. Add tool definitions
4. Update documentation
5. Add tests

## Examples

See `examples/` directory for complete usage examples:

- `ec2_management.py` - EC2 instance management
- `s3_operations.py` - S3 bucket operations
- `lambda_deployment.py` - Lambda function deployment
- `monitoring.py` - CloudWatch monitoring

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: [repository-url]/issues
- Documentation: [docs-url]
