variable "aws_region" {}
variable "redis_name" { default = "cloudcurio-redis" }
variable "elasticache_mode" { default = "serverless" } # serverless|cluster
provider "aws" { region = var.aws_region }

resource "aws_elasticache_serverless_cache" "this" {
  count = var.elasticache_mode == "serverless" ? 1 : 0
  engine = "redis"
  name   = var.redis_name
}

resource "aws_elasticache_replication_group" "this" {
  count = var.elasticache_mode == "cluster" ? 1 : 0
  replication_group_id = var.redis_name
  engine = "redis"
  engine_version = "7.1"
  node_type = "cache.t4g.small"
  number_cache_clusters = 2
  automatic_failover_enabled = true
}

output "redis_endpoint" {
  value = var.elasticache_mode == "serverless" ? aws_elasticache_serverless_cache.this[0].endpoint["port"] : aws_elasticache_replication_group.this[0].primary_endpoint_address
}
