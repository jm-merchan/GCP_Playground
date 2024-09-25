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


output "gcs_bucket_snapshot" {
  value = google_storage_bucket.vault_license_bucket.name
}

output "sa-name" {
  value = google_service_account.main.email
}

output "init_script_node1" {
  value = <<EOF

# Initialize Vault
vault status # wait for vault to show as unsealed

vault operator init -format=json > output.json
cat output.json | jq -r .root_token > root.token
export VAULT_TOKEN=$(cat root.token)

# Save info in GCP Secrets
gcloud secrets create root_token_${var.region1}_${random_string.vault.result} --replication-policy="automatic"
echo -n $VAULT_TOKEN | gcloud secrets versions add root_token_${var.region1}_${random_string.vault.result} --data-file=-
gcloud secrets create vault_init_data_${var.region1}_${random_string.vault.result} --replication-policy="automatic"
cat output.json | gcloud secrets versions add vault_init_data_${var.region1}_${random_string.vault.result} --data-file=-

# Enable Audit Logging
vault audit enable file file_path=/var/log/vault.log

# Create Prometheus token and update Ops Agent Configuration with Token
vault policy write prometheus-metrics /opt/vault/prometheus.hcl
vault token create -field=token -policy prometheus-metrics > prometheus.token
export PROMETHEUS_TOKEN=$(cat prometheus.token)
sudo sed -ibak "s/VAULT_TOKEN_PROMETHEUS/$PROMETHEUS_TOKEN/g" /etc/google-cloud-ops-agent/config.yaml
sudo systemctl restart google-cloud-ops-agent

# Enable Dead Server clean-up, min-quorum should be set in accordance to cluster size
vault operator raft autopilot set-config -cleanup-dead-servers=true -dead-server-last-contact-threshold=1m -min-quorum=3

  EOF
}

output "init_script_node2-X" {
  value = <<EOF

# Obtain root token
export VAULT_TOKEN=$(gcloud secrets versions access latest --secret=root_token_${var.region1}_${random_string.vault.result})

# Create Prometheus token and update Ops Agent Configuration with Token
vault token create -field=token -policy prometheus-metrics > prometheus.token
export PROMETHEUS_TOKEN=$(cat prometheus.token)
sudo sed -ibak "s/VAULT_TOKEN_PROMETHEUS/$PROMETHEUS_TOKEN/g" /etc/google-cloud-ops-agent/config.yaml
sudo systemctl restart google-cloud-ops-agent

  EOF
}

output "init_auto_snapshot" {
  value = <<EOF

# From your terminal
# Enable automatic snapshots
export VAULT_TOKEN=$(gcloud secrets versions access latest --secret=root_token_${var.region1}_${random_string.vault.result} --project=${var.project_id})
gcloud iam service-accounts keys create sa-keys__${var.region1}_${random_string.vault.result}.json --iam-account=${google_service_account.main.email}
VAULT_ADDR=https://${local.fqdn_ext}:8200 vault write sys/storage/raft/snapshot-auto/config/hourly interval="1h" retain=10 path_prefix="snapshots/" storage_type=google-gcs google_gcs_bucket=${google_storage_bucket.vault_license_bucket.name} google_service_account_key="@sa-keys__${var.region1}_${random_string.vault.result}.json"

  EOF
}