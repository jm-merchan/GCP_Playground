resource "random_string" "boundary" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "google_kms_key_ring" "key_ring" {
  depends_on = [time_sleep.wait_20_seconds]
  name       = "kms-boundary-keyring-${random_string.boundary.result}"
  location   = "global"
}

resource "google_kms_crypto_key" "boundary_key_root" {
  name     = "kms-boundary-key-root-${random_string.boundary.result}"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key" "boundary_key_worker_auth" {
  name     = "kms-boundary-key-worker-auth-${random_string.boundary.result}"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key" "boundary_key_recovery" {
  name     = "kms-boundary-key-recovery-${random_string.boundary.result}"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key" "boundary_key_bsr" {
  name     = "kms-boundary-key-bsr-${random_string.boundary.result}"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}


# Enable Cloud KMS API - https://console.developers.google.com/apis/api/cloudkms.googleapis.com/overview?
resource "google_project_service" "cloudkms" {
  project = var.project_id
  service = "cloudkms.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "time_sleep" "wait_20_seconds" {
  depends_on      = [google_project_service.cloudkms, google_project_service.servicenetworking]
  create_duration = "20s"
}