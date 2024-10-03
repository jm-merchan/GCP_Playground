resource "google_kms_key_ring" "key_ring" {
  name     = "gke-kms-vault-keyring-${random_string.vault.result}"
  location = var.location
}

resource "google_kms_crypto_key" "vault_key" {
  name     = "gke-kms-vault-key-${random_string.vault.result}"
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

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [google_project_service.cloudkms]
  create_duration = "60s"
}