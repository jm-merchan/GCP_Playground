output "internal_url-lb" {
  value = google_compute_region_url_map.lb.name
}

locals {
  fqdn = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
}

output "fqdn_8200" {
  value = "https://${local.fqdn}:8200"
}

output "fqdn" {
  value = "https://${local.fqdn}"
}