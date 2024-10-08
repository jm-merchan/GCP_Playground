provider "vault" {
  address = "https://vault-europe-southwest1-cd1h.josemerchan-6b5afd.gcp.sbx.hashicorpdemo.com:8200"
  token = "hvs.xigmKeXhkUQUDZdRGI1yzddj"
}


resource "vault_policy" "ssh_signer" {
  name = "ssh"
  policy = file("ssh_policy.hcl")
}

resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"
  policy = file("boundary-controller-policy.hcl")
}

resource "vault_token" "boundary_token_ssh" {
  no_default_policy = true
  period            = "20m"
  policies          = ["ssh"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-ssh"
  }
}


resource "vault_mount" "ssh" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "This is an example SSH Engine"

  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_ssh_secret_backend_ca" "boundary" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true

    /*
  provisioner "local-exec" {
    command = "echo '${self.public_key}' > ../vault_ca.pub"
  }
  */
}


resource "vault_token" "boundary_token" {
  no_default_policy = true
  period            = "24h"
  policies          = ["boundary-controller", "ssh"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-boundary"
  }
}


resource "vault_ssh_secret_backend_role" "signer" {
  backend                 = vault_mount.ssh.path
  name                    = "boundary-client"
  key_type                = "ca"
  allow_user_certificates = true
  default_user            = "admin"
  default_extensions = {
    "permit-pty" : ""
  }
  allowed_users      = "*"
  allowed_extensions = "*"
}
