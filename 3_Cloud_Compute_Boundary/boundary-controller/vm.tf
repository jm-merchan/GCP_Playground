# Data source to fetch the latest Debian image from Google Cloud
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  boundary_version = var.boundary_enterprise == false ? "boundary=${var.boundary_version}-*" : "boundary-enterprise=${var.boundary_version}+ent-*"
}


locals {
  boundary_user_data = templatefile("${path.module}/templates/install_boundary.sh.tpl",
    {
      crypto_key_root     = google_kms_crypto_key.boundary_key_root.name
      cryto_key_worker    = google_kms_crypto_key.boundary_key_worker_auth.name
      crypto_key_recovery = google_kms_crypto_key.boundary_key_recovery.name
      crypto_key_bsr      = google_kms_crypto_key.boundary_key_bsr.name
      key_ring            = google_kms_key_ring.key_ring.name
      cluster_name        = "${var.cluster-name}-${var.region}-${random_string.boundary.result}.${local.domain}"
      location            = var.location
      project             = var.project_id
      tls_secret_id       = var.tls_secret_id
      boundary_license    = var.boundary_license
      boundary_version    = local.boundary_version
      boundary_log_path   = var.boundary_log_path
      db_username         = var.db_username
      db_password         = var.db_password
      database_name       = "${var.instance_name}${random_string.boundary.result}"
      database_address    = google_sql_database_instance.postgres_instance.private_ip_address
    }
  )
}

resource "google_compute_instance_template" "boundary" {
  depends_on   = [acme_certificate.certificate]
  name_prefix  = "${var.region}-boundary"
  machine_type = var.machine_type

  tags = ["${var.region}-boundary"]

  metadata_startup_script = local.boundary_user_data

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
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]

    email = google_service_account.main.email
  }

  description          = "The instance template of the compute deployment for BOUNDARY."
  instance_description = "An instance of the compute deployment for BOUNDARY."

  lifecycle {
    create_before_destroy = true
  }

}



data "google_compute_zones" "available" {
  region = var.region
}

resource "google_compute_region_instance_group_manager" "boundary" {
  name                      = "${var.region}-boundary-group-manager"
  region                    = var.region
  base_instance_name        = "${var.region}-boundary"
  distribution_policy_zones = data.google_compute_zones.available.names

  target_size = var.node_count

  named_port {
    name = "api"
    port = 9200
  }

  named_port {
    name = "cluster"
    port = 9201
  }

  named_port {
    name = "ops"
    port = 9203
  }

  version {
    instance_template = google_compute_instance_template.boundary.self_link
  }
}
