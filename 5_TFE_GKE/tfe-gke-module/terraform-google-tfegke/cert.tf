# Generate a private key so you can create a CA cert with it.
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Example with Let's Encrypt
# Based on https://itnext.io/lets-encrypt-certs-with-terraform-f870def3ce6d

data "google_dns_managed_zone" "env_dns_zone" {
  name = var.dns_zone_name_ext
}

locals {
  # Remove . from domain
  domain = substr(data.google_dns_managed_zone.env_dns_zone.dns_name, 0, length(data.google_dns_managed_zone.env_dns_zone.dns_name) - 1)
}

provider "acme" {
  server_url = local.acme_prod
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # Testing
  # server_url = "https://acme-v02.api.letsencrypt.org/directory" # Production
  # server_url = "https://acme.zerossl.com/v2/DV90" #https://zerossl.com/documentation/acme/
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
  common_name     = "tfe-${var.region}-${random_string.tfe.result}.${local.domain}"
  # subject_alternative_names = ["*.${local.domain}"] # To have wildcard

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT = var.project_id
    }
  }

  depends_on = [acme_registration.registration]
}


locals {
  # Use let's encrypt certificate if possible otherwise go with self-signed
  tfe_cert = try(lookup(acme_certificate.certificate, "certificate_pem"), "")
  tfe_ca   = try(lookup(acme_certificate.certificate, "issuer_pem"), "")
  tfe_key  = try(lookup(acme_certificate.certificate, "private_key_pem"), "")
}

locals {
  tls_data = {
    #tfe_ca   = base64encode(tls_self_signed_cert.ca.cert_pem)
    tfe_ca = base64encode(local.tfe_ca)
    #tfe_cert = base64encode(tls_locally_signed_cert.server.cert_pem)
    tfe_cert = base64encode(local.tfe_cert)
    #tfe_pk   = base64encode(tls_private_key.server.private_key_pem)
    tfe_pk = base64encode(local.tfe_key)
  }
}

locals {
  secret = jsonencode(local.tls_data)
}
