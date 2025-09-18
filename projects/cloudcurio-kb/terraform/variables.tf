variable "kc_url" {}
variable "kc_client_id" {}
variable "kc_client_secret" {}
variable "realm" { default = "cloudcurio" }
variable "oidc_client_id" { default = "kb-bff" }

variable "cf_api_token" {}
variable "cf_account_id" {}
variable "zone" {}
variable "hostname" { description = "kb.example.com" }
