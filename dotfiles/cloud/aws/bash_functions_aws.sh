#!/bin/bash
# AWS Functions - Template
# Category: Cloud Provider - Amazon Web Services
# Description: Functions for managing AWS resources via AWS CLI
# Prerequisites: AWS CLI installed and configured (aws configure)
# Usage: Source this file in your .bashrc or .zshrc
# Author: Knowledge Base Team
# Last Updated: 2025-11-01

# =============================================================================
# EC2 Instance Management
# =============================================================================

# Function: aws_list_instances
# Description: List all EC2 instances with details
# Usage: aws_list_instances [region]
# Arguments:
#   $1 - Optional AWS region (default: from config)
# Returns: List of EC2 instances
# Example: aws_list_instances us-east-1
aws_list_instances() {
    local region_arg=""
    if [[ $# -gt 0 ]]; then
        region_arg="--region $1"
    fi
    
    aws ec2 describe-instances $region_arg \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
        --output table
}

# Function: aws_start_instance
# Description: Start an EC2 instance
# Usage: aws_start_instance <instance_id> [region]
# Arguments:
#   $1 - Instance ID
#   $2 - Optional AWS region
# Returns: 0 on success
# Example: aws_start_instance i-1234567890abcdef0 us-east-1
aws_start_instance() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Instance ID required"
        echo "Usage: aws_start_instance <instance_id> [region]"
        return 1
    fi
    
    local instance_id="$1"
    local region_arg=""
    if [[ $# -gt 1 ]]; then
        region_arg="--region $2"
    fi
    
    echo "Starting instance: $instance_id"
    aws ec2 start-instances --instance-ids "$instance_id" $region_arg
}

# Function: aws_stop_instance
# Description: Stop an EC2 instance
# Usage: aws_stop_instance <instance_id> [region]
# Arguments:
#   $1 - Instance ID
#   $2 - Optional AWS region
# Returns: 0 on success
# Example: aws_stop_instance i-1234567890abcdef0 us-east-1
aws_stop_instance() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Instance ID required"
        echo "Usage: aws_stop_instance <instance_id> [region]"
        return 1
    fi
    
    local instance_id="$1"
    local region_arg=""
    if [[ $# -gt 1 ]]; then
        region_arg="--region $2"
    fi
    
    echo "Stopping instance: $instance_id"
    aws ec2 stop-instances --instance-ids "$instance_id" $region_arg
}

# Function: aws_instance_status
# Description: Get status of an EC2 instance
# Usage: aws_instance_status <instance_id> [region]
# Arguments:
#   $1 - Instance ID
#   $2 - Optional AWS region
# Returns: Instance status
# Example: aws_instance_status i-1234567890abcdef0
aws_instance_status() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Instance ID required"
        echo "Usage: aws_instance_status <instance_id> [region]"
        return 1
    fi
    
    local instance_id="$1"
    local region_arg=""
    if [[ $# -gt 1 ]]; then
        region_arg="--region $2"
    fi
    
    aws ec2 describe-instance-status --instance-ids "$instance_id" $region_arg
}

# =============================================================================
# S3 Bucket Management
# =============================================================================

# Function: aws_list_buckets
# Description: List all S3 buckets
# Usage: aws_list_buckets
# Returns: List of S3 buckets
aws_list_buckets() {
    aws s3 ls
}

# Function: aws_list_bucket_contents
# Description: List contents of an S3 bucket
# Usage: aws_list_bucket_contents <bucket_name> [path]
# Arguments:
#   $1 - Bucket name
#   $2 - Optional path within bucket
# Returns: List of objects
# Example: aws_list_bucket_contents my-bucket data/
aws_list_bucket_contents() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Bucket name required"
        echo "Usage: aws_list_bucket_contents <bucket_name> [path]"
        return 1
    fi
    
    local bucket="$1"
    local path="${2:-}"
    
    aws s3 ls "s3://${bucket}/${path}"
}

# Function: aws_get_bucket_size
# Description: Get total size of S3 bucket
# Usage: aws_get_bucket_size <bucket_name>
# Arguments:
#   $1 - Bucket name
# Returns: Bucket size
# Example: aws_get_bucket_size my-bucket
aws_get_bucket_size() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Bucket name required"
        echo "Usage: aws_get_bucket_size <bucket_name>"
        return 1
    fi
    
    local bucket="$1"
    
    aws s3 ls "s3://${bucket}" --recursive --summarize | grep "Total Size"
}

# Function: aws_sync_to_s3
# Description: Sync local directory to S3 bucket
# Usage: aws_sync_to_s3 <source_dir> <bucket_name> [path]
# Arguments:
#   $1 - Source directory
#   $2 - Bucket name
#   $3 - Optional path in bucket
# Returns: 0 on success
# Example: aws_sync_to_s3 ./data my-bucket backups/
aws_sync_to_s3() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Source directory and bucket name required"
        echo "Usage: aws_sync_to_s3 <source_dir> <bucket_name> [path]"
        return 1
    fi
    
    local source="$1"
    local bucket="$2"
    local path="${3:-}"
    
    echo "Syncing $source to s3://${bucket}/${path}"
    aws s3 sync "$source" "s3://${bucket}/${path}"
}

# Function: aws_sync_from_s3
# Description: Sync S3 bucket to local directory
# Usage: aws_sync_from_s3 <bucket_name> <target_dir> [path]
# Arguments:
#   $1 - Bucket name
#   $2 - Target directory
#   $3 - Optional path in bucket
# Returns: 0 on success
# Example: aws_sync_from_s3 my-bucket ./data backups/
aws_sync_from_s3() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Bucket name and target directory required"
        echo "Usage: aws_sync_from_s3 <bucket_name> <target_dir> [path]"
        return 1
    fi
    
    local bucket="$1"
    local target="$2"
    local path="${3:-}"
    
    echo "Syncing s3://${bucket}/${path} to $target"
    aws s3 sync "s3://${bucket}/${path}" "$target"
}

# =============================================================================
# Lambda Functions
# =============================================================================

# Function: aws_list_lambdas
# Description: List all Lambda functions
# Usage: aws_list_lambdas [region]
# Arguments:
#   $1 - Optional AWS region
# Returns: List of Lambda functions
aws_list_lambdas() {
    local region_arg=""
    if [[ $# -gt 0 ]]; then
        region_arg="--region $1"
    fi
    
    aws lambda list-functions $region_arg \
        --query 'Functions[*].[FunctionName,Runtime,LastModified]' \
        --output table
}

# Function: aws_invoke_lambda
# Description: Invoke a Lambda function
# Usage: aws_invoke_lambda <function_name> [payload]
# Arguments:
#   $1 - Function name
#   $2 - Optional JSON payload
# Returns: Function response
# Example: aws_invoke_lambda my-function '{"key":"value"}'
aws_invoke_lambda() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Function name required"
        echo "Usage: aws_invoke_lambda <function_name> [payload]"
        return 1
    fi
    
    local function_name="$1"
    local payload="${2:-{}}"
    
    aws lambda invoke \
        --function-name "$function_name" \
        --payload "$payload" \
        response.json
    
    cat response.json
    rm response.json
}

# =============================================================================
# CloudWatch Logs
# =============================================================================

# Function: aws_list_log_groups
# Description: List CloudWatch log groups
# Usage: aws_list_log_groups [region]
# Arguments:
#   $1 - Optional AWS region
# Returns: List of log groups
aws_list_log_groups() {
    local region_arg=""
    if [[ $# -gt 0 ]]; then
        region_arg="--region $1"
    fi
    
    aws logs describe-log-groups $region_arg \
        --query 'logGroups[*].logGroupName' \
        --output table
}

# Function: aws_tail_logs
# Description: Tail CloudWatch logs
# Usage: aws_tail_logs <log_group> [minutes]
# Arguments:
#   $1 - Log group name
#   $2 - Optional minutes to look back (default: 10)
# Returns: Recent log entries
# Example: aws_tail_logs /aws/lambda/my-function 30
aws_tail_logs() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Log group name required"
        echo "Usage: aws_tail_logs <log_group> [minutes]"
        return 1
    fi
    
    local log_group="$1"
    local minutes="${2:-10}"
    local start_time=$(($(date +%s) - (minutes * 60)))000
    
    aws logs tail "$log_group" --since "${minutes}m" --follow
}

# =============================================================================
# RDS Database Management
# =============================================================================

# Function: aws_list_rds_instances
# Description: List all RDS instances
# Usage: aws_list_rds_instances [region]
# Arguments:
#   $1 - Optional AWS region
# Returns: List of RDS instances
aws_list_rds_instances() {
    local region_arg=""
    if [[ $# -gt 0 ]]; then
        region_arg="--region $1"
    fi
    
    aws rds describe-db-instances $region_arg \
        --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]' \
        --output table
}

# Function: aws_start_rds_instance
# Description: Start an RDS instance
# Usage: aws_start_rds_instance <instance_id> [region]
# Arguments:
#   $1 - RDS instance identifier
#   $2 - Optional AWS region
# Returns: 0 on success
# Example: aws_start_rds_instance my-database us-east-1
aws_start_rds_instance() {
    if [[ $# -lt 1 ]]; then
        echo "Error: RDS instance identifier required"
        echo "Usage: aws_start_rds_instance <instance_id> [region]"
        return 1
    fi
    
    local instance_id="$1"
    local region_arg=""
    if [[ $# -gt 1 ]]; then
        region_arg="--region $2"
    fi
    
    echo "Starting RDS instance: $instance_id"
    aws rds start-db-instance --db-instance-identifier "$instance_id" $region_arg
}

# Function: aws_stop_rds_instance
# Description: Stop an RDS instance
# Usage: aws_stop_rds_instance <instance_id> [region]
# Arguments:
#   $1 - RDS instance identifier
#   $2 - Optional AWS region
# Returns: 0 on success
# Example: aws_stop_rds_instance my-database us-east-1
aws_stop_rds_instance() {
    if [[ $# -lt 1 ]]; then
        echo "Error: RDS instance identifier required"
        echo "Usage: aws_stop_rds_instance <instance_id> [region]"
        return 1
    fi
    
    local instance_id="$1"
    local region_arg=""
    if [[ $# -gt 1 ]]; then
        region_arg="--region $2"
    fi
    
    echo "Stopping RDS instance: $instance_id"
    aws rds stop-db-instance --db-instance-identifier "$instance_id" $region_arg
}

# =============================================================================
# IAM Management
# =============================================================================

# Function: aws_list_users
# Description: List all IAM users
# Usage: aws_list_users
# Returns: List of IAM users
aws_list_users() {
    aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table
}

# Function: aws_list_roles
# Description: List all IAM roles
# Usage: aws_list_roles
# Returns: List of IAM roles
aws_list_roles() {
    aws iam list-roles --query 'Roles[*].[RoleName,CreateDate]' --output table
}

# =============================================================================
# Cost and Billing
# =============================================================================

# Function: aws_get_cost_current_month
# Description: Get AWS costs for current month
# Usage: aws_get_cost_current_month
# Returns: Cost breakdown
aws_get_cost_current_month() {
    local start_date=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
    local end_date=$(date +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE
}

# =============================================================================
# Profile and Configuration
# =============================================================================

# Function: aws_switch_profile
# Description: Switch AWS CLI profile
# Usage: aws_switch_profile <profile_name>
# Arguments:
#   $1 - Profile name
# Returns: 0 on success
# Example: aws_switch_profile production
aws_switch_profile() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Profile name required"
        echo "Usage: aws_switch_profile <profile_name>"
        return 1
    fi
    
    export AWS_PROFILE="$1"
    echo "Switched to AWS profile: $1"
}

# Function: aws_current_profile
# Description: Show current AWS profile
# Usage: aws_current_profile
# Returns: Current profile name
aws_current_profile() {
    echo "Current AWS profile: ${AWS_PROFILE:-default}"
}

# Function: aws_list_profiles
# Description: List all configured AWS profiles
# Usage: aws_list_profiles
# Returns: List of profiles
aws_list_profiles() {
    aws configure list-profiles
}
