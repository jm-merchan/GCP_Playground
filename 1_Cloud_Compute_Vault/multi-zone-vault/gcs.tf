/*
variable "vault_license_filepath" {
  type        = string
  description = "Filepath to location of Vault license file"

}

variable "storage_location" {
  type        = string
  description = "The location of the storage bucket for the Vault license."
}

variable "vault_license_name" {
  type        = string
  description = "Filename for Vault license file"
  default     = "vault.hclic"
}

*/


/*
resource "random_pet" "gcs" {
  length = 2
}

resource "google_storage_bucket" "vault_license_bucket" {
  location                    = var.storage_location
  name                        = "gcs-vault-license-${random_pet.gcs.id}"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "vault_license" {
  name   = var.vault_license_name
  source = var.vault_license_filepath
  bucket = google_storage_bucket.vault_license_bucket.name
}
*/

/*
resource "google_storage_bucket_iam_member" "member_object" {
  bucket = google_storage_bucket_object.vault_license.bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.main.email}"
}

resource "google_storage_bucket_iam_member" "member_bucket" {
  bucket = google_storage_bucket_object.vault_license.bucket
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.main.email}"
}
*/