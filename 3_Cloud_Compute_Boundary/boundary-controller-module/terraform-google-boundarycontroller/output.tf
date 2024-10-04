locals {
  fqdn_ext = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
}

output "fqdn_9200" {
  value = "https://${local.fqdn_ext}:9200"
}

output "fqdn_443" {
  value = "https://${local.fqdn_ext}"
}

output "remove_database_before_destroy" {
  description = "Postgres database is loaded with data out-of-band and so it is required to remove it out of band too"
  value       = "gcloud sql instances delete ${google_sql_database_instance.postgres_instance.name} --project=${var.project_id}"
}


output "remove_peering_before_destroy" {
  value = "gcloud compute networks peerings delete ${google_service_networking_connection.private_vpc_connection.peering} --network=${var.create_vpc == true ? google_compute_network.global_vpc[0].name : local.vpc_name} --project=${var.project_id}"
}

output "key_ring" {
  value = google_kms_key_ring.key_ring.name
}

output "crypto_key" {
  value = google_kms_crypto_key.boundary_key_recovery.name
}

output "crypto_key_worker" {
  value = google_kms_crypto_key.boundary_key_worker_auth.name
}

output "project" {
  value = var.project_id
}

output "location" {
  value = var.location
}