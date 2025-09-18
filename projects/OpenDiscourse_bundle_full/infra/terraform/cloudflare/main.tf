terraform {
  required_providers { cloudflare = { source = "cloudflare/cloudflare" version = ">= 4.0" } }
}
provider "cloudflare" { api_token = var.cloudflare_api_token }
variable "account_id" {}
variable "zone_id" {}
variable "root_domain" {}

resource "cloudflare_access_application" "admin" {
  zone_id = var.zone_id
  name    = "OpenDiscourse Admin"
  domain  = "admin.${var.root_domain}"
  session_duration = "24h"
}
resource "cloudflare_access_policy" "admin_policy" {
  application_id = cloudflare_access_application.admin.id
  zone_id        = var.zone_id
  name           = "Allow Admins"
  decision       = "allow"
  include { emails = ["you@example.com"] }
}
resource "cloudflare_ruleset" "custom_waf" {
  zone_id = var.zone_id
  name    = "OD Custom WAF"
  kind    = "zone"
  phase   = "http_request_firewall_custom"
  rules {
    action = "managed_challenge"
    expression = "http.request.uri.path starts_with \"/api/comments\" and http.request.method in {\"POST\"}"
    description = "Challenge on comment posts"
    enabled = true
  }
}
resource "cloudflare_r2_bucket" "log" { account_id = var.account_id name = "od-cf-logs" }
resource "cloudflare_logpush_job" "http" {
  dataset   = "http_requests"
  enabled   = true
  name      = "od-http"
  logpull_options = "fields=RayID,ClientIP,EdgeStartTimestamp,ClientRequestURI,ClientRequestUserAgent,CacheCacheStatus,EdgeResponseStatus&timestamps=rfc3339"
  destination_conf = "r2://account-id=${var.account_id}&bucket_name=${cloudflare_r2_bucket.log.name}&filename_prefix=http/"
  zone_id   = var.zone_id
}
