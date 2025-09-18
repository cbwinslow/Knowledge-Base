terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "account_id" {}
variable "zone_id" {}
variable "cloudflare_api_token" {}

# Example: D1 database (placeholder resource names).
# resource "cloudflare_d1_database" "stackhub" {
#   account_id = var.account_id
#   name       = "stackhub_db"
# }
