#!/usr/bin/env bash

export instance_id="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H Metadata-Flavor:Google)"

export local_ipv4="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H Metadata-Flavor:Google)"

# install package

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y ${boundary_version} jq logrotate

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install


echo "Configuring system time"
timedatectl set-timezone UTC

# removing any default installation files from /opt/boundary/tls/
mkdir /opt/boundary
mkdir /opt/boundary/tls

# /opt/boundary/tls should be readable by all users of the system
sudo chmod 0755 /opt/boundary
sudo chmod 0755 /opt/boundary/tls

# boundary-key.pem should be readable by the boundary group only
sudo touch /opt/boundary/tls/boundary-key.pem
sudo chown root:boundary /opt/boundary/tls/boundary-key.pem
sudo chmod 0640 /opt/boundary/tls/boundary-key.pem

secret_result=$(gcloud secrets versions access latest --secret=${tls_secret_id})

sudo jq -r .boundary_cert <<< "$secret_result" | base64 -d > /opt/boundary/tls/boundary-cert.pem
sudo jq -r .boundary_ca <<< "$secret_result" | base64 -d > /opt/boundary/tls/boundary-ca.pem
sudo jq -r .boundary_pk <<< "$secret_result" | base64 -d > /opt/boundary/tls/boundary-key.pem

# Add intermediate to cert chain
sudo echo -e "\n" >> /opt/boundary/tls/boundary-cert.pem
sudo jq -r .boundary_ca <<< "$secret_result" | base64 -d >>  /opt/boundary/tls/boundary-cert.pem

sudo echo ${boundary_license} > /opt/boundary/boundary.hclic
# boundary.hclic should be readable by the boundary group only
sudo chown root:boundary /opt/boundary/boundary.hclic
sudo chmod 0640 /opt/boundary/boundary.hclic

sudo cat << EOF > /etc/boundary.d/boundary.hcl
disable_mlock = true

controller {
  name = "boundary-controller"
  description = "Boundary Controller Cluster"
  database {
    url                   = "postgresql://${db_username}:${db_password}@${database_address}:5432/${database_name}"
    max_open_connections  = 5
  }
  graceful_shutdown_wait_duration = "10s"
  public_cluster_addr             = "${cluster_name}:9201"
  # https://developer.hashicorp.com/boundary/docs/enterprise/licensing
  license                         = "file:///opt/boundary/boundary.hclic"
}

# API listener configuration block
listener "tcp" {
  # Should be the address of the NIC that the controller server will be reached on
  address       = "0.0.0.0"
  tls_cert_file = "/opt/boundary/tls/boundary-cert.pem"
  tls_key_file  = "/opt/boundary/tls/boundary-key.pem"
  tls_disable   = false
  purpose       = "api"
}

# Data-plane listener configuration block (used for worker coordination)
listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address       = "0.0.0.0"
  purpose       = "cluster"
}

listener "tcp" {
  address       = "0.0.0.0"
  tls_cert_file = "/opt/boundary/tls/boundary-cert.pem"
  tls_key_file  = "/opt/boundary/tls/boundary-key.pem"
  tls_disable   = false
  purpose       = "ops"
}

kms "gcpckms" {
  purpose     = "root"
  key_ring    = "${key_ring}"  
  crypto_key  = "${crypto_key_root}"
  project     = "${project}"
  region      = "${location}"
}

kms "gcpckms" {
  purpose     = "worker-auth"
  key_ring    = "${key_ring}"
  crypto_key  = "${cryto_key_worker}"
  project     = "${project}"
  region      = "${location}"
}

kms "gcpckms" {
  purpose     = "recovery"
  key_ring    = "${key_ring}"
  crypto_key  = "${crypto_key_recovery}"
  project     = "${project}"
  region      = "${location}"
}

kms "gcpckms" {
  purpose     = "bsr"
  key_ring    = "${key_ring}"
  crypto_key  = "${crypto_key_bsr}"
  project     = "${project}"
  region      = "${location}"
}


events {
  audit_enabled        = true
  observations_enabled = true
  sysevents_enabled    = true
  telemetry_enabled    = true

  sink "stderr" {
    name        = "all-events"
    description = "All events sent to stderr"
    event_types = ["*"]
    format      = "cloudevents-json"
  }

  sink {
    name        = "controller-audit-sink"
    description = "Audit sent to a file"
    event_types = ["audit"]
    format      = "cloudevents-json"

    file {
      path      = "/var/log/boundary/"
      file_name = "audit.log"
    }

    audit_config {
      audit_filter_overrides {
        secret    = "encrypt"
        sensitive = "hmac-sha256"
      }
    }
  }
}

EOF

# boundary.hcl should be readable by the boundary group only
sudo chown root:root /etc/boundary.d
sudo chown root:boundary /etc/boundary.d/boundary.hcl
sudo chmod 640 /etc/boundary.d/boundary.hcl

# Adding some random time to initialize Boundary
sleep_time=$((RANDOM % 30 + 1))
echo "Sleeping for $sleep_time seconds..."
sleep $sleep_time

# Init Boundary
boundary database init \
   -skip-auth-method-creation \
   -skip-host-resources-creation \
   -skip-scopes-creation \
   -skip-target-creation \
   -config /etc/boundary.d/boundary.hcl

sudo systemctl enable boundary
sudo systemctl start boundary

echo "Setup boundary profile"
cat <<PROFILE | sudo tee /etc/profile.d/boundary.sh
export BOUNDARY_ADDR="https://127.0.0.1:9200"
export BOUNDARY_TLS_INSECURE="true"
PROFILE


# Create log rotate configuration
sudo cat << EOF > /etc/logrotate.d/boundary
${boundary_log_path} {
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
logging:
  receivers:
    boundary_audit_logs:
      type: files
      include_paths:
        - ${boundary_log_path}
  service:
    pipelines:
      boundary_pipeline:
        receivers: [boundary_audit_logs]

EOF

sudo systemctl restart google-cloud-ops-agent

# Add permissions to boundary user to write logs
sudo mkdir /var/log/boundary
sudo touch /var/log/boundary/audit.log
sudo chown boundary:boundary /var/log/boundary
sudo chown boundary:boundary /var/log/boundary/audit.log
EOF
