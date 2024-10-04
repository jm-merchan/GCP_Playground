# Remove HTTPS from boundary URI
locals {
  boundary_upstream = regex("^https?://([^/]+)", data.terraform_remote_state.local_backend.outputs.boundary_fqdn_443)[0]
}

locals {
  boundary_user_data = templatefile("${path.module}/templates/install_boundary.sh.tpl",
    {
     # activation_token = boundary_worker.ingress_pki_worker.controller_generated_activation_token
      upstream          = local.boundary_upstream
      worker_type       = var.worker_tag
      key_ring          = data.terraform_remote_state.local_backend.outputs.key_ring
      cryto_key_worker  = data.terraform_remote_state.local_backend.outputs.crypto_key_worker
      project           = var.project_id
      location          = "global"
    }
  )
}

# Service Account for host, we will use it for firewall rules
resource "google_service_account" "worker" {
  account_id   = "iam-worker1"
  display_name = "Service account for worker"
}
/*
resource "boundary_worker" "ingress_pki_worker" {
  scope_id                    = "global"
  name                        = "pki-worker1"
  worker_generated_auth_token = ""
}
*/

resource "google_compute_instance" "worker" {
  name         = "worker1"
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
    access_config {}
  }

  service_account {
    scopes = ["cloud-platform"]
    email  = google_service_account.worker.email
  }
  metadata_startup_script = local.boundary_user_data
}

resource "google_project_iam_member" "boundary_kms" {
  member  = "serviceAccount:${google_service_account.worker.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
}

# Role for KMS Access has get and useToEncrypt and Decrypt permissions
resource "google_project_iam_custom_role" "kms_role" {
  role_id     = "boundary_kms_worker"
  title       = "boundary-kms-worker"
  description = "Custom role for Boundary Worker KMS binding"
  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeys.get",
    "cloudkms.locations.get",
    "cloudkms.locations.list",
    "resourcemanager.projects.get"
  ]
}