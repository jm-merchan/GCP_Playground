#!/usr/bin/env bash

export instance_id="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H Metadata-Flavor:Google)"

export public_ipv4="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H Metadata-Flavor:Google)"


google_compute_instance.worker.network_interface[0].access_config[0].nat_ip
# install package

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y boundary-enterprise jq logrotate

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

echo "Configuring system time"
timedatectl set-timezone UTC

# Create recording folder
mkdir /tmp/boundary/
sudo chown boundary:boundary /tmp/boundary/

sudo cat << EOF > /etc/systemd/system/boundary.service
[Unit]
Description="HashiCorp Boundary - Identity-based access management for dynamic infrastructure"
Documentation=https://www.boundaryproject.io/docs
#StartLimitIntervalSec=60
#StartLimitBurst=3

[Service]
ExecStart=/usr/bin/boundary server -config=/etc/boundary.d/pki-worker.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

EOF


sudo cat << EOF > /etc/boundary.d/pki-worker.hcl
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0"
  purpose = "proxy"
  tls_disable = true
}

listener "tcp" {
  address = "0.0.0.0"
  purpose = "ops"
  tls_disable = true
}

worker {
  name = "$instance_id"
  public_addr = "$public_ipv4"
  initial_upstreams = ["${upstream}:9201"]
  recording_storage_minimum_available_capacity = "500MB"
  recording_storage_path="/tmp/boundary"
  tags {
    type = ["${worker_type}", "${function}"]
  }
}

kms "gcpckms" {
  purpose     = "worker-auth"
  key_ring    = "${key_ring}"
  crypto_key  = "${cryto_key_worker}"
  project     = "${project}"
  region      = "${location}"
}


EOF

# boundary.hcl should be readable by the boundary group only
sudo chown root:root /etc/boundary.d
sudo chown root:boundary /etc/boundary.d/pki-worker.hcl
sudo chmod 640 /etc/boundary.d/pki-worker.hcl

sudo systemctl daemon-reload
sudo systemctl enable boundary
sudo systemctl start boundary
