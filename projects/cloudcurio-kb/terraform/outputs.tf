output "tunnel_cname" { value = cloudflare_tunnel.kb.cname }
output "realm" { value = keycloak_realm.kb.realm }
output "client_id" { value = keycloak_openid_client.bff.client_id }
