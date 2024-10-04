output "boundary_fqdn_9200" {
  value = module.boundary.fqdn_9200
}

output "boundary_fqdn_443" {
  value = module.boundary.fqdn_443
}

output "crypto_key" {
  value = module.boundary.crypto_key
}

output "key_ring" {
  value = module.boundary.key_ring
}

output "location" {
  value = module.boundary.location
}

output "project" {
  value = module.boundary.project
}

output "remove_database_before_destroy" {
  value = module.boundary.remove_database_before_destroy
}

output "remove_peering_before_destroy" {
  value = module.boundary.remove_peering_before_destroy
}

# Outputs for cluster1
output "vault_fqdn_8200" {
  value = module.vault1.fqdn_8200
}

output "vault_init_remote" {
  value = module.vault1.init_remote
}

output "vault_fqdn_8201" {
  value = module.vault1.fqdn_8201
}

output "vault_read_vault_token" {
  value = module.vault1.read_vault_token
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "crypto_key_worker" {
  value = module.boundary.crypto_key_worker
}