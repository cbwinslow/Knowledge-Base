terraform {
  required_version = ">= 1.6.0"
  required_providers {
    keycloak = { source = "mrparkers/keycloak", version = "~> 4.4" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.40" }
  }
}
