
resource "google_storage_bucket" "tfe_bucket" {
  location                    = var.storage_location
  name                        = "gcs-tfe-${random_string.tfe.result}"
  uniform_bucket_level_access = true
  force_destroy               = true #to force destroy even if data in bucket
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
  bucket = google_storage_bucket.tfe_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_storage_hmac_key" "tfe-s3-access" {
  service_account_email = google_service_account.service_account.email
}