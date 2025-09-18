provider "keycloak" {
  client_id     = var.kc_client_id
  client_secret = var.kc_client_secret
  url           = var.kc_url
  realm         = "master"
}
provider "cloudflare" {
  api_token = var.cf_api_token
}
resource "keycloak_realm" "kb" {
  realm        = var.realm
  display_name = "CloudCurio KB"
}
resource "keycloak_openid_client" "bff" {
  realm_id              = keycloak_realm.kb.id
  client_id             = var.oidc_client_id
  name                  = "kb-bff"
  enabled               = true
  standard_flow_enabled = true
  access_type           = "CONFIDENTIAL"
  valid_redirect_uris   = ["https://${var.hostname}/*"]
}
resource "cloudflare_zone" "zone" {
  account_id = var.cf_account_id
  name       = var.zone
}
resource "cloudflare_tunnel" "kb" {
  account_id = var.cf_account_id
  name       = "cloudcurio-kb"
}
resource "cloudflare_tunnel_config" "kb" {
  account_id = var.cf_account_id
  tunnel_id  = cloudflare_tunnel.kb.id
  config {
    ingress_rule {
      hostname = var.hostname
      service  = "http://localhost:80"
    }
    ingress_rule { service = "http_status:404" }
  }
}
resource "cloudflare_record" "kb" {
  zone_id = cloudflare_zone.zone.id
  name    = var.hostname
  type    = "CNAME"
  value   = cloudflare_tunnel.kb.cname
  proxied = true
}
