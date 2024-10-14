# For reference https://surajblog.medium.com/workload-identity-in-gke-with-terraform-9678a7a1d9c0

# Role for KMS Access has get and useToEncrypt and Decrypt permissions
resource "google_project_iam_custom_role" "kms_role" {
  role_id     = "tfekms${random_string.tfe.result}"
  title       = "tfe-kms-${random_string.tfe.result}"
  description = "Custom role for Vault KMS binding"
  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeys.get",
    "cloudkms.locations.get",
    "cloudkms.locations.list",
    "resourcemanager.projects.get",
    "iam.serviceAccounts.getAccessToken" # For workload identity
  ]
}

resource "google_service_account" "service_account" {
  account_id   = "${var.region}-satfe-${random_string.tfe.result}"
  display_name = "Service Account for TFE"
}


# Provide access to Vault Service Account
resource "google_project_iam_member" "tfe_kms" {
  member  = "serviceAccount:${google_service_account.service_account.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
}

resource "google_project_iam_member" "workload_identity-role" {
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
  member  = "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.tfe.metadata[0].name}/terraform]"
}
