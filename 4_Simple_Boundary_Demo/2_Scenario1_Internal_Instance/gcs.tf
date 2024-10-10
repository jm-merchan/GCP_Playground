
resource "google_storage_bucket" "miniobucket" {
  location                    = "EU"
  name                        = "gcs-session-recording-${random_string.string.result}"
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

# Enable GCS Interoperability (Manual Step)
output "gcs_interoperability_instruction" {
  value = <<EOT
To enable S3 compatibility, follow these steps:

1. Navigate to Google Cloud Console:
   https://console.cloud.google.com/storage/settings

2. Under "Interoperability", enable the "Interoperability API".

3. Create a new HMAC key.

4. Use the HMAC Access Key and Secret Key to interact with the GCS bucket using S3-compatible tools.

Bucket Name: ${google_storage_bucket.miniobucket.name} 
EOT

}


resource "google_storage_bucket_iam_member" "member_object" {
  bucket = google_storage_bucket.miniobucket.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.worker.email}"
}

/*
resource "boundary_storage_bucket" "gcs" {
  name        = "GCP Storage"
  description = "GCP Storage Bucket"
  scope_id    = "global"
  plugin_name = "minio"
  bucket_name = google_storage_bucket.miniobucket.name
  attributes_json = jsonencode({
    "region" = "${var.region}",
  "disable_credential_rotation" : true })

  # recommended to pass in aws secrets using a file() or using environment variables
  # the secrets below must be generated in aws by creating a aws iam user with programmatic access
  secrets_json = jsonencode({
    "access_key_id"     = var.gcs_access_key
    "secret_access_key" = var.gcs_secret_key
  })
  worker_filter = " \"upstream\" in \"/tags/type\" "
}
*/