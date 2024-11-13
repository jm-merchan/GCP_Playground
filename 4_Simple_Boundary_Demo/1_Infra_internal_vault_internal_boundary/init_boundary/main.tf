# https://developer.hashicorp.com/boundary/docs/install-boundary/initialize#create-your-first-login-account
provider "boundary" {
  addr             = "https://boundary-europe-southwest1-s39l.josemerchan-2c4ef2.gcp.sbx.hashicorpdemo.com"
  tls_insecure     = true
  recovery_kms_hcl = <<EOT
    kms "gcpckms" {
    purpose     = "recovery"
    key_ring    = "kms-boundary-keyring-s39l"
    crypto_key  = "kms-boundary-key-recovery-s39l"
    project     = "hc-ef850f7ac0e04fa581e54b3fba8"
    region      = "global"
    }
EOT
}

resource "boundary_auth_method" "password" {
  name        = "Password auth method"
  description = "Password auth method"
  type        = "password"
  scope_id    = "global"
}

resource "boundary_account_password" "myuser" {
  name           = "admin"
  description    = "User account for adminr"
  login_name     = var.boundary_user
  password       = var.boundary_password
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_user" "myuser" {
  name        = "admin"
  description = "Initial Admin User"
  account_ids = [boundary_account_password.myuser.id]
  scope_id    = "global"
}

resource "boundary_role" "org_admin" {
  scope_id        = "global"
  grant_scope_ids = ["global"]
  grant_strings = [
    "ids=*;type=*;actions=*"
  ]
  principal_ids = [boundary_user.myuser.id]
}

output "auth_method" {
  value = boundary_auth_method.password.id
}

