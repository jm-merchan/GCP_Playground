locals {
  fqdn_ext     = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
  fqdn_int443  = substr(google_dns_record_set.vip-int1.name, 0, length(google_dns_record_set.vip-int1.name) - 1)
  fqdn_int8200 = substr(google_dns_record_set.vip-int2.name, 0, length(google_dns_record_set.vip-int2.name) - 1)
}

output "fqdn_8200" {
  value = "https://${local.fqdn_ext}:8200"
}

output "fqdn_443" {
  value = "https://${local.fqdn_ext}"
}

output "pri_fqdn_443" {
  value = "https://${local.fqdn_int443}"
}

output "pri_fqdn_8200" {
  value = "https://${local.fqdn_int8200}:8200"
}
/*
#Print the data needed
output "public_ips" {
  value = [
    for instance in data.google_compute_instance.intance_data :
    [
      instance.name, instance.network_interface.0.access_config.0.nat_ip
    ]
  ]
}
*/