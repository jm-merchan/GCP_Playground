output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.default.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.default.endpoint
  description = "GKE Cluster Host"
}

output "configure_kubectl" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.default.name} --region ${var.region} --project ${var.project_id}"
}

locals {
  fqdn_ext8200 = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
  fqdn_ext8201 = substr(google_dns_record_set.vip_cluster_port.name, 0, length(google_dns_record_set.vip_cluster_port.name) - 1)
}

output "fqdn_8200" {
  value = "https://${local.fqdn_ext8200}:8200"
}

output "fqdn_8201" {
  value = "https://${local.fqdn_ext8201}:8201"
}

output "init_remote" {
  value = <<EOF
# Initialize Vault
export VAULT_ADDR=https://${local.fqdn_ext8200}:8200
export VAULT_SKIP_VERIFY=true
vault status
curl -k $VAULT_ADDR

vault operator init -format=json > output.json
cat output.json | jq -r .root_token > root.token
export VAULT_TOKEN=$(cat root.token)
sleep 10

# Save info in GCP Secrets
gcloud secrets create root_token_${var.region}_${random_string.vault.result} --replication-policy="automatic" --project=${var.project_id}
echo -n $VAULT_TOKEN | gcloud secrets versions add root_token_${var.region}_${random_string.vault.result} --project=${var.project_id} --data-file=-
gcloud secrets create vault_init_data_${var.region}_${random_string.vault.result} --replication-policy="automatic" --project=${var.project_id}
cat output.json | gcloud secrets versions add vault_init_data_${var.region}_${random_string.vault.result} --project=${var.project_id} --data-file=-
rm output.json
rm root.token

# Enable Audit Logging
# vault audit enable file file_path=/var/log/vault.log

# Enable Dead Server clean-up, min-quorum should be set in accordance to cluster size
vault operator raft autopilot set-config -cleanup-dead-servers=true -dead-server-last-contact-threshold=1m -min-quorum=3

# Enable automatic snapshot
gcloud iam service-accounts keys create sa-keys__${var.region}_${random_string.vault.result}.json --iam-account=${google_service_account.service_account.email}
vault write sys/storage/raft/snapshot-auto/config/hourly interval="1h" retain=10 path_prefix="snapshots/" storage_type=google-gcs google_gcs_bucket=${google_storage_bucket.vault_license_bucket.name} google_service_account_key="@sa-keys__${var.region}_${random_string.vault.result}.json"
rm sa-keys__${var.region}_${random_string.vault.result}.json
  EOF
}