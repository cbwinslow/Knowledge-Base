variable "cloudflare_api_token" { type = string }
variable "account_id" { type = string }
variable "zone_id" { type = string }
variable "repo" { type = string, description = "GitHub org/repo (e.g., cbw/cloudcurio-stackhub)" }
variable "production_branch" { type = string, default = "main" }
variable "pages_project_name" { type = string, default = "cloudcurio-stackhub" }
variable "worker_name" { type = string, default = "cloudcurio-stackhub-api" }
variable "root_domain" { type = string, default = "cloudcurio.cc" }
variable "api_subdomain" { type = string, default = "api" }
variable "access_email_domain" { type = string, default = "cloudcurio.cc" }
variable "r2_bucket_name" { type = string, default = "stackhub-artifacts" }
variable "queue_name" { type = string, default = "stackhub-embed-queue" }
variable "vectorize_index_name" { type = string, default = "stackhub_index" }
