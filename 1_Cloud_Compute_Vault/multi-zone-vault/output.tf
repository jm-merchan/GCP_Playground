output "internal_url-lb" {
  value = google_compute_region_url_map.lb.name
}

output "vip" {
  value = google_compute_address.internal.address
}


locals {
  # Remove . from domain
  vip_fqdn = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
}

output "fqdn_8200" {
  value = "https://${local.vip_fqdn}:8200"
}

output "fqdn" {
  value = "https://${local.vip_fqdn}"
}