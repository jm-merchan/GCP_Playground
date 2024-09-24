# Generate a private key so you can create a CA cert with it.
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Example with Let's Encrypt
# Based on https://itnext.io/lets-encrypt-certs-with-terraform-f870def3ce6d

locals {
  # Remove . from domain
  domain = substr(data.google_dns_managed_zone.env_dns_zone.dns_name, 0, length(data.google_dns_managed_zone.env_dns_zone.dns_name) - 1)
}

provider "acme" {
  server_url = local.acme_prod
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # Testing
  # server_url = "https://acme-v02.api.letsencrypt.org/directory" # Production
  # server_url = "https://acme.zerossl.com/v2/DV90" #https://zerossl.com/documentation/acme/
  # If you create a cert and then you want to modify the issuer do a terraform destroy first and then re-apply.
}


resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = "${var.cluster-name}-${var.region1}-${random_string.vault.result}.${local.domain}"
  # subject_alternative_names = ["*.${local.domain}"] # To have wildcard

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT = var.project_id
    }
  }

  depends_on = [acme_registration.registration]
}


/*
# Uncomment if you want to use self-signed instead of ACME
# Create a CA cert with the private key you just generated.
resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "vault.server.com"
  }

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true

  # provisioner "local-exec" {
  #   command = "echo '${tls_self_signed_cert.ca.cert_pem}' > ./vault-ca.pem"
  # }
}

# Generate another private key. This one will be used
# To create the certs on your Vault nodes
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048

  # provisioner "local-exec" {
  #   command = "echo '${tls_private_key.server.private_key_pem}' > ./vault-key.pem"
  # }
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "vault.server.com"
  }

  dns_names = [
    var.shared_san,
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]

  # provisioner "local-exec" {
  #   command = "echo '${tls_locally_signed_cert.server.cert_pem}' > ./vault-crt.pem"
  # }
}

*/

locals {
  # Use let's encrypt certificate if possible otherwise go with self-signed
  vault_cert = try(lookup(acme_certificate.certificate, "certificate_pem"), "")
  vault_ca   = try(lookup(acme_certificate.certificate, "issuer_pem"), "")
  vault_key  = try(lookup(acme_certificate.certificate, "private_key_pem"), "")
}

locals {
  tls_data = {
    #vault_ca   = base64encode(tls_self_signed_cert.ca.cert_pem)
    vault_ca = base64encode(local.vault_ca)
    #vault_cert = base64encode(tls_locally_signed_cert.server.cert_pem)
    vault_cert = base64encode(local.vault_cert)
    #vault_pk   = base64encode(tls_private_key.server.private_key_pem)
    vault_pk = base64encode(local.vault_key)
  }
}

locals {
  secret = jsonencode(local.tls_data)
}

resource "google_compute_region_ssl_certificate" "main" {
  region = var.region1
  # certificate = "${tls_locally_signed_cert.server.cert_pem}\n${tls_self_signed_cert.ca.cert_pem}"
  # private_key = tls_private_key.server.private_key_pem
  certificate = "${local.vault_cert}\n${local.vault_ca}"
  private_key = local.vault_key

  description = "The regional SSL certificate of the private load balancer for Vault."
  name_prefix = "vault-${random_string.vault.result}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_secret_manager_secret" "secret_tls" {
  secret_id = var.tls_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_version_basic" {
  secret      = google_secret_manager_secret.secret_tls.id
  secret_data = local.secret
}