
resource "google_storage_bucket" "vault_license_bucket" {
  location                    = var.storage_location
  name                        = "gcs-vault-snapshot-${random_string.vault.result}"
  uniform_bucket_level_access = true
  force_destroy               = true #to force destroy even if backups are saved in the bucket
  versioning {
    enabled = true
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 # Keep snapshots for 30 days
    }
  }
}

resource "google_storage_bucket_iam_member" "member_object" {
  bucket = google_storage_bucket.vault_license_bucket.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.service_account.email}"
}