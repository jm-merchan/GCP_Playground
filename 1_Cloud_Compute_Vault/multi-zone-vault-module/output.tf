# Outputs for cluster1
output "cluster1_fqdn_8200" {
  value = module.vault.fqdn_8200
}

output "cluster1_fqdn_443" {
  value = module.vault.fqdn_443
}

output "cluster1_pri_fqdn_443" {
  value = module.vault.pri_fqdn_443
}

output "cluster1_pri_fqdn_8200" {
  value = module.vault.fqdn_8200
}


output "cluster1_gcs_bucket_snapshot" {
  value = module.vault.gcs_bucket_snapshot
}

output "cluster1_sa-name" {
  value = module.vault.sa-name
}

# Outputs for cluster2
output "cluster2_fqdn_8200" {
  value = module.vault.fqdn_8200
}

output "cluster2_fqdn_443" {
  value = module.vault.fqdn_443
}

output "cluster2_pri_fqdn_443" {
  value = module.vault.pri_fqdn_443
}

output "cluster2_pri_fqdn_8200" {
  value = module.vault.fqdn_8200
}


output "cluster2_gcs_bucket_snapshot" {
  value = module.vault.gcs_bucket_snapshot
}

output "cluster2_sa-name" {
  value = module.vault.sa-name
}