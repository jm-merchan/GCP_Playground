#!/usr/bin/env bash

export instance_id="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H Metadata-Flavor:Google)"

export local_ipv4="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H Metadata-Flavor:Google)"

# install package

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y ${vault_version} jq logrotate

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install


echo "Configuring system time"
timedatectl set-timezone UTC

# removing any default installation files from /opt/vault/tls/
sudo rm -rf /opt/vault/tls/*

# /opt/vault/tls should be readable by all users of the system
sudo chmod 0755 /opt/vault/tls

# vault-key.pem should be readable by the vault group only
sudo touch /opt/vault/tls/vault-key.pem
sudo chown root:vault /opt/vault/tls/vault-key.pem
sudo chmod 0640 /opt/vault/tls/vault-key.pem

secret_result=$(gcloud secrets versions access latest --secret=${tls_secret_id})

sudo jq -r .vault_cert <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-cert.pem
sudo jq -r .vault_ca <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-ca.pem
sudo jq -r .vault_pk <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-key.pem
# Add intermediate to cert chain
sudo echo -e "\n" >> /opt/vault/tls/vault-cert.pem
sudo jq -r .vault_ca <<< "$secret_result" | base64 -d >>  /opt/vault/tls/vault-cert.pem

sudo echo ${vault_license} > /opt/vault/vault.hclic
# vault.hclic should be readable by the vault group only
sudo chown root:vault /opt/vault/vault.hclic
sudo chmod 0640 /opt/vault/vault.hclic

sudo cat << EOF > /etc/vault.d/vault.hcl
disable_performance_standby = true
ui = true
disable_mlock = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$instance_id"
  retry_join {
    auto_join               = "provider=gce tag_value=${resource_name}"
    auto_join_scheme        = "https"
    leader_tls_servername   = "${leader_tls_servername}"
    leader_ca_cert_file     = "/opt/vault/tls/vault-ca.pem"
    leader_client_cert_file = "/opt/vault/tls/vault-cert.pem"
    leader_client_key_file  = "/opt/vault/tls/vault-key.pem"
  }
}
cluster_addr = "https://$local_ipv4:8201"
api_addr = "https://$local_ipv4:8200"

listener "tcp" {
  address                           = "0.0.0.0:8200"
  tls_disable                       = false
  tls_cert_file                     = "/opt/vault/tls/vault-cert.pem"
  tls_key_file                      = "/opt/vault/tls/vault-key.pem"
  tls_client_ca_file                = "/opt/vault/tls/vault-ca.pem"
  x_forwarded_for_authorized_addrs  = "0.0.0.0/0"
}

seal "gcpckms" {
  project    = "${project}"
  region     = "${location}"
  key_ring   = "${key_ring}"
  crypto_key = "${crypto_key}"
}

license_path = "/opt/vault/vault.hclic"

# https://cloud.google.com/monitoring/agent/ops-agent/third-party/vault?hl=es-419
telemetry {
  prometheus_retention_time = "10m"
  disable_hostname = false
}

EOF

# vault.hcl should be readable by the vault group only
sudo chown root:root /etc/vault.d
sudo chown root:vault /etc/vault.d/vault.hcl
sudo chmod 640 /etc/vault.d/vault.hcl

sudo systemctl enable vault
sudo systemctl start vault

echo "Setup Vault profile"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
PROFILE


# Create log rotate configuration
sudo cat << EOF > /etc/logrotate.d/vault
${vault_log_path} {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}

EOF

# Create Ops Agent configuration for Vault
sudo cat << EOF > /etc/google-cloud-ops-agent/config.yaml
metrics:
  receivers:
    vault:
      type: vault
      token: VAULT_TOKEN_PROMETHEUS
      endpoint: 127.0.0.1:8200
      insecure_skip_verify: true
      insecure: false
  service:
    pipelines:
      vault:
        receivers:
          - vault
logging:
  receivers:
    vault_audit_logs:
      type: files
      include_paths:
        - ${vault_log_path}
  service:
    pipelines:
      vault_pipeline:
        receivers: [vault_audit_logs]

EOF

sudo systemctl restart google-cloud-ops-agent

# Add permissions to vault user to write logs
sudo touch /var/log/vault.log
sudo chown vault:vault /var/log/vault.log
# sudo chown vault:vault /var/log

# Adding the prometheus monitoring policy
sudo cat << EOF > /opt/vault/prometheus.hcl
  path "/sys/metrics" {
  capabilities = ["read"]
  }
  
EOF
