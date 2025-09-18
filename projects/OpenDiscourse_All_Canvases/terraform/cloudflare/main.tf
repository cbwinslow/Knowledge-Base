provider "cloudflare" {}
resource "cloudflare_zone" "od" { zone = "opendiscourse.net" }
