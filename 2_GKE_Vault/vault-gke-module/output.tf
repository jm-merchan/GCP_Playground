# Outputs for cluster1
output "cluster1_fqdn_8200" {
  value = module.vault1.fqdn_8200
}

output "cluster1_init_remote" {
  value = module.vault1.init_remote
}

output "cluster1_fqdn_8201" {
  value = module.vault1.fqdn_8201
}


# --------------------------------------

# Outputs for cluster2
output "cluster2_fqdn_8200" {
  value = module.vault2.fqdn_8200
}

output "cluster2_init_remote" {
  value = module.vault2.init_remote
}

output "cluster2_fqdn_8201" {
  value = module.vault2.fqdn_8201
}
