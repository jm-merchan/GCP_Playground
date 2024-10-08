
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "Demo"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

resource "boundary_scope" "project" {
  name                     = "Scenario1"
  description              = "Project Scope"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_static" "example" {
  name        = "Boundary Static Credential Store"
  description = "Credential Store for First Target"
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_ssh_private_key" "example" {
  name                = "Private key for target1"
  description         = "SSH Private Key"
  credential_store_id = boundary_credential_store_static.example.id
  username            = var.ssh_user
  private_key         = var.private_key
}


resource "boundary_host_catalog_static" "gcp_instance" {
  name        = "Scenario1 Catalog"
  description = "Scenario1"
  scope_id    = boundary_scope.project.id
}


# Details for GCP instance
resource "boundary_host_static" "bar" {
  name            = "Scenario1_Private_Compute_instance"
  host_catalog_id = boundary_host_catalog_static.gcp_instance.id
  address         = google_compute_instance.default.network_interface[0].network_ip
}

resource "boundary_host_set_static" "bar" {
  name            = "Scenario1_Private_Compute_instance"
  host_catalog_id = boundary_host_catalog_static.gcp_instance.id

  host_ids = [
    boundary_host_static.bar.id
  ]
}



resource "boundary_target" "gcp_linux_private" {
  type        = "tcp"
  name        = "Scenario1_Private_Compute_instance"
  description = "GCP COMpute Linux Private Target"
  #egress_worker_filter     = " \"sm-egress-downstream-worker1\" in \"/tags/type\" "
  ingress_worker_filter    = " \"${var.worker_tag}\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.bar.id
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_ssh_private_key.example.id
  ]

}

resource "boundary_alias_target" "scenario1" {
  name           = "Scenario1_Private_CloudCompute_instance"
  description    = "GCP Linux Private Target"
  scope_id       = "global"
  value          = var.scenario1_target_alias
  destination_id = boundary_target.gcp_linux_private.id
  #authorize_session_host_id = boundary_host_static.bar.id
}


/*
  Details for Kubernetes POD
*/

# Details for GCP instance
resource "boundary_host_static" "vault" {
  name            = "Scenario1_Private_Vault"
  host_catalog_id = boundary_host_catalog_static.gcp_instance.id
  address         = "vault-active.vault.svc.cluster.local"
}

resource "boundary_host_set_static" "vault" {
  name            = "Scenario1_Private_Vault"
  host_catalog_id = boundary_host_catalog_static.gcp_instance.id

  host_ids = [
    boundary_host_static.vault.id
  ]
}



resource "boundary_target" "vault" {
  type                     = "tcp"
  name                     = "Scenario1_Private_Vault_instance"
  description              = "HashiCorp Vault Private Target"
  egress_worker_filter     = " \"downstream\" in  \"/tags/type\" "
  ingress_worker_filter    = " \"upstream\"   in  \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 8200
  host_source_ids = [
    boundary_host_set_static.vault.id
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
  ]

}

resource "boundary_alias_target" "vault" {
  name           = "Scenario1_Private_Vault_instance"
  description    = "Vault Private Target"
  scope_id       = "global"
  value          = "vault.gcp.boundary.demo"
  destination_id = boundary_target.vault.id
  #authorize_session_host_id = boundary_host_static.bar.id
}

##########

resource "boundary_scope" "project_ssh" {
  name                     = "SSH Session Injection"
  description              = "SSH Session Injection"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_vault" "vault" {
  name            = "certificates-store"
  description     = "Vault credential"
  address         = var.vault_addr
  tls_skip_verify = true
  token           = vault_token.boundary_token_ssh.client_token
  scope_id        = boundary_scope.project_ssh.id
}

resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  name                = "certificates-library"
  description         = "Certificate Library"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh-client-signer/sign/boundary-client" # change to Vault backend path
  username            = "admin"
  key_type            = "ecdsa"
  key_bits            = 521

  extensions = {
    permit-pty = ""
  }
}



resource "boundary_host_catalog_static" "gcp_instance_ssh_injection" {
  name        = "Target with SSH Injection"
  description = "SSH catalog"
  scope_id    = boundary_scope.project_ssh.id
}

resource "boundary_host_static" "ssh" {
  name            = "SSH Session Injection"
  host_catalog_id = boundary_host_catalog_static.gcp_instance_ssh_injection.id
  address         = google_compute_instance.default.network_interface[0].network_ip
}

resource "boundary_host_set_static" "ssh" {
  name            = "ssh-injection-host-set"
  host_catalog_id = boundary_host_catalog_static.gcp_instance_ssh_injection.id

  host_ids = [
    boundary_host_static.ssh.id
  ]
}


resource "boundary_target" "ssh" {
  type        = "ssh"
  name        = "Host Target with SSH Injection"
  description = "Host Target with SSH Injection"
  #egress_worker_filter     = " \"sm-egress-downstream-worker1\" in \"/tags/type\" "
  ingress_worker_filter    = " \"${var.worker_tag}\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project_ssh.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.ssh.id
  ]

  # Comment this to avoid brokeing the credentials

  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh.id
  ]

}


resource "boundary_alias_target" "target_ssh_injection" {
  name           = "Scenario3_ssh_injection"
  description    = "Scenario3_ssh_injection"
  scope_id       = "global"
  value          = "scenario1-ssh.gcp.boundary.demo"
  destination_id = boundary_target.ssh.id
  #authorize_session_host_id = boundary_host_static.bar.id
}
