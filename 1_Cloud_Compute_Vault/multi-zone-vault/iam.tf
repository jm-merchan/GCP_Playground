
# Service Account for Vault to auto-unseal and auto-join
resource "google_service_account" "main" {
  account_id   = "iam-vault-${random_string.vault.result}"
  display_name = "Vault KMS and auto-join for auto-unseal"
}

# Role for autojoin has list permissions
resource "google_project_iam_custom_role" "autojoin_role" {
  role_id     = "vaultautojoin${random_string.vault.result}"
  title       = "vault-auto-join-${random_string.vault.result}"
  description = "Custom role for Vault auto-join"
  permissions = [
    "compute.zones.list",
    "compute.instances.list"
  ]
}

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
    "resourcemanager.projects.get"
  ]
}

resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = google_project_iam_custom_role.kms_role.name

  members = ["serviceAccount:${google_service_account.main.email}"]
}

resource "google_project_iam_member" "vault_auto_join" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.autojoin_role.name
}

resource "google_secret_manager_secret_iam_member" "secret_manager_member" {
  secret_id = var.tls_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.main.email}"
}


