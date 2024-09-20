output "internal_url-lb" {
  value = google_compute_region_url_map.lb.name
}

output "vip" {
  value = google_compute_address.internal.address
}

output "fqdn" {
  value = google_dns_record_set.vip.name
}