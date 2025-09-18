variable "gcp_project" {}
variable "gcp_region" {}
variable "redis_tier" { default = "BASIC" } # BASIC|STANDARD_HA
variable "redis_name" { default = "cloudcurio-redis" }

provider "google" { project = var.gcp_project; region = var.gcp_region }

resource "google_redis_instance" "this" {
  name = var.redis_name
  tier = var.redis_tier
  memory_size_gb = 2
  region = var.gcp_region
}

output "redis_host" { value = google_redis_instance.this.host }
output "redis_port" { value = google_redis_instance.this.port }
