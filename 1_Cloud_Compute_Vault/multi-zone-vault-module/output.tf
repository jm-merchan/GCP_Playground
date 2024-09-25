# Outputs for cluster1
output "cluster1_fqdn_8200" {
  value = module.vault1.fqdn_8200
}

output "cluster1_init_script_node1" {
  value = module.vault1.init_script_node1
}

output "cluster1_init_script_node2-X" {
  value = module.vault1.init_script_node2-X
}

output "cluster1_init_auto_snapshot" {
  value = module.vault1.init_auto_snapshot
}


output "cluster1_gcs_bucket_snapshot" {
  value = module.vault1.gcs_bucket_snapshot
}

output "cluster1_init_remote" {
  value = module.vault1.init_remote
}

# Outputs for cluster2
output "cluster2_fqdn_8200" {
  value = module.vault2.fqdn_8200
}

output "cluster2_init_script_node1" {
  value = module.vault2.init_script_node1
}

output "cluster2_init_script_node2-X" {
  value = module.vault2.init_script_node2-X
}

output "cluster2_init_auto_snapshot" {
  value = module.vault2.init_auto_snapshot
}

output "cluster2_gcs_bucket_snapshot" {
  value = module.vault2.gcs_bucket_snapshot
}

output "cluster2_init_remote" {
  value = module.vault2.init_remote
}