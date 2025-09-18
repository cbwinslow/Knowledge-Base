resource "cloudflare_pages_project" "app" {
  account_id = var.account_id
  name       = var.pages_project_name
  production_branch = var.production_branch
  deployment_configs { production { environment_variables = { NEXT_PUBLIC_STACKHUB_API = "https://${var.api_subdomain}.${var.root_domain}", NODE_VERSION = "20" } } }
}
resource "cloudflare_record" "app_root" { zone_id = var.zone_id; name = var.root_domain; type = "CNAME"; value = cloudflare_pages_project.app.subdomain; proxied = true }
resource "cloudflare_record" "api" { zone_id = var.zone_id; name = "${var.api_subdomain}.${var.root_domain}"; type = "CNAME"; value = "workers.dev"; proxied = true }
resource "cloudflare_d1_database" "db" { account_id = var.account_id; name = "stackhub_db" }
resource "cloudflare_r2_bucket" "artifacts" { account_id = var.account_id; name = var.r2_bucket_name }
resource "cloudflare_turnstile_widget" "stackhub" { account_id = var.account_id; name = "stackhub-public-forms"; mode = "invisible" }
resource "cloudflare_access_application" "api" { account_id = var.account_id; name = "StackHub API Admin"; domain = "${var.api_subdomain}.${var.root_domain}"; session_duration = "24h" }
resource "cloudflare_access_policy" "api_allow_org" { account_id = var.account_id; application_id = cloudflare_access_application.api.id; name = "Allow ${var.access_email_domain}"; precedence = 1; decision = "allow"; include { email_domain = [var.access_email_domain] } }
resource "cloudflare_queue" "embed" { account_id = var.account_id; queue_name = var.queue_name }
resource "cloudflare_workers_script" "api" {
  account_id = var.account_id
  name       = var.worker_name
  content = file("../cloudflare/dist/index.js")
  compatibility_date = "2024-11-04"
  d1_database_binding { name = "DB" database_id = cloudflare_d1_database.db.id }
  r2_bucket_binding   { name = "ARTIFACTS" bucket_name = cloudflare_r2_bucket.artifacts.name }
  analytics_engine_binding { dataset = "stackhub_events" }
  vectorize_binding   { name = "VEC" index_name = var.vectorize_index_name }
  ai_binding          { name = "AI" }
  queue_producer_binding { binding = "EMBED_QUEUE" queue_name = cloudflare_queue.embed.queue_name }
}
output "pages_subdomain" { value = cloudflare_pages_project.app.subdomain }
output "d1_database_id" { value = cloudflare_d1_database.db.id }
output "turnstile_site_key" { value = cloudflare_turnstile_widget.stackhub.site_key }
