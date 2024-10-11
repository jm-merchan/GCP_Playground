# Basic VM
# https://cloud.google.com/docs/terraform/create-vm-instance

# Data source to fetch the latest Debian image from Google Cloud
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

data "google_compute_zones" "available" {
  region = var.region
}


# Service Account for host, we will use it for firewall rules
resource "google_service_account" "main" {
  account_id   = "iam-target1"
  display_name = "Service accountn for first target"
}


locals {
  target_data = templatefile("${path.module}/templates/target.sh.tpl",
    {
      # activation_token = boundary_worker.ingress_pki_worker.controller_generated_activation_token
      ca_pub = vault_ssh_secret_backend_ca.boundary.public_key
    }
  )
}

resource "google_compute_instance" "default" {
  name         = "target1"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[0]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network    = data.terraform_remote_state.local_backend.outputs.vpc_id
    subnetwork = google_compute_subnetwork.subnet.id
    # access_config {}
  }

  service_account {
    scopes = ["cloud-platform"]
    email  = google_service_account.main.email
  }

  metadata_startup_script = local.target_data

  lifecycle {
    ignore_changes = [
      metadata_startup_script
    ]
  }
}
