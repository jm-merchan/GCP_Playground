# For reference https://surajblog.medium.com/workload-identity-in-gke-with-terraform-9678a7a1d9c0

# Role for KMS Access has get and useToEncrypt and Decrypt permissions
resource "google_project_iam_custom_role" "kms_role" {
  role_id     = "vaultkms${random_string.vault.result}"
  title       = "vault-kms-${random_string.vault.result}"
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
  account_id   = "${var.region}-savault-${random_string.vault.result}"
  display_name = "Service Account for Vault"
}


# Provide access to Vault Service Account
resource "google_project_iam_member" "vault_kms" {
  member  = "serviceAccount:${google_service_account.service_account.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
}

resource "google_project_iam_member" "workload_identity-role" {
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
  member  = "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.vault.metadata[0].name}/${var.cluster-name}]"
}