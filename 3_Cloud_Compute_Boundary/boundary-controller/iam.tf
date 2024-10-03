

# Service Account for Boundary
resource "google_service_account" "main" {
  account_id   = "iam-boundary-${random_string.boundary.result}"
  display_name = "Boundary Service Account"
}

# Role for KMS Access has get and useToEncrypt and Decrypt permissions
resource "google_project_iam_custom_role" "kms_role" {
  role_id     = "boundarykms${random_string.boundary.result}"
  title       = "boundary-kms-${random_string.boundary.result}"
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


# Role to create secrets with root token
resource "google_project_iam_custom_role" "secret_creator" {
  role_id     = "boundarylog${random_string.boundary.result}"
  title       = "boundary-log-${random_string.boundary.result}"
  description = "Custom role for Vault secret creation"
  permissions = [
    "secretmanager.secrets.create",
    "secretmanager.secrets.get",
    "secretmanager.versions.add",
    "secretmanager.versions.access"
  ]
}

resource "google_project_iam_member" "boundary_secret" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.secret_creator.name
}

resource "google_project_iam_member" "boundary_kms" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
}


resource "google_project_iam_member" "boundary_log" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
}

resource "google_secret_manager_secret_iam_member" "secret_manager_member" {
  secret_id = var.tls_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "logging" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = "roles/logging.logWriter"
}



/*

# Role for autojoin has list permissions
resource "google_project_iam_custom_role" "autojoin_role" {
  role_id     = "boundaryautojoin${random_string.boundary.result}"
  title       = "boundary-auto-join-${random_string.boundary.result}"
  description = "Custom role for Vault auto-join"
  permissions = [
    "compute.zones.list",
    "compute.instances.list"
  ]
}

# Role for automatic snapshot and sa json retrival
resource "google_project_iam_custom_role" "keys" {
  role_id     = "boundarykeys${random_string.boundary.result}"
  title       = "boundary-akeys-${random_string.boundary.result}"
  description = "Custom role for Vault auto snapshot with json credential"
  permissions = [
    "iam.serviceAccountKeys.create"
  ]
}

resource "google_project_iam_member" "boundary_keys" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.keys.name
}

resource "google_project_iam_member" "boundary_auto_join" {
  member  = "serviceAccount:${google_service_account.main.email}"
  project = var.project_id
  role    = google_project_iam_custom_role.autojoin_role.name
}
*/

