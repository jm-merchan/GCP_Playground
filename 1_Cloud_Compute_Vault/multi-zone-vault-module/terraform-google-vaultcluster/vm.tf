# Data source to fetch the latest Debian image from Google Cloud
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  vault_version = var.vault_enterprise == false ? "vault=${var.vault_version}-*" : "vault-enterprise=${var.vault_version}+ent-*"
}


locals {
  vault_user_data = templatefile("${path.module}/templates/install_vault.sh.tpl",
    {
      crypto_key            = google_kms_crypto_key.vault_key.name
      key_ring              = google_kms_key_ring.key_ring.name
      leader_tls_servername = "${var.cluster-name}-${var.region1}-${random_string.vault.result}.${local.domain}"
      location              = var.location
      project               = var.project_id
      resource_name         = "${var.region1}-vault-${random_string.vault.result}"
      tls_secret_id         = "${var.tls_secret_id}-${random_string.vault.result}"
      vault_license         = var.vault_license
      vault_version         = local.vault_version
      vault_log_path        = var.vault_log_path
    }
  )
}

resource "google_compute_instance_template" "vault" {
  depends_on   = [acme_certificate.certificate]
  name_prefix  = "${var.region1}-vault-${random_string.vault.result}"
  machine_type = var.machine_type

  tags = ["${var.region1}-vault-${random_string.vault.result}"]

  metadata_startup_script = local.vault_user_data

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size
    disk_type    = var.disk_type
    mode         = "READ_WRITE"
    type         = "PERSISTENT"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet1.self_link
    # Uncomment to provide with Public IPs
    /*
    access_config {

    }
    */
  }
  service_account {
    scopes = ["cloud-platform"]

    email = google_service_account.main.email
  }

  description          = "The instance template of the compute deployment for Vault."
  instance_description = "An instance of the compute deployment for Vault."

  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_zones" "available" {
  region = var.region1
}

resource "google_compute_region_instance_group_manager" "vault" {
  name                      = "${var.region1}-vault-group-manager-${random_string.vault.result}"
  region                    = var.region1
  base_instance_name        = "${var.region1}-vault"
  distribution_policy_zones = data.google_compute_zones.available.names

  target_size = var.node_count

  named_port {
    name = "https"
    port = 8200
  }

  named_port {
    name = "cluster"
    port = 8201
  }

  named_port {
    name = "kmip"
    port = 5696
  }

  version {
    name              = google_compute_instance_template.vault.name
    instance_template = google_compute_instance_template.vault.self_link
  }
  update_policy {
    type = "OPPORTUNISTIC"
    //type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = length(data.google_compute_zones.available.names)
    max_unavailable_fixed        = 0
  }
}
