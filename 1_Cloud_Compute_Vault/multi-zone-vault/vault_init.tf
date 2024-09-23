provider "terracurl" {}

locals {
  fqdn = substr(google_dns_record_set.vip.name, 0, length(google_dns_record_set.vip.name) - 1)
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [google_compute_forwarding_rule.ext-lb2, acme_certificate.certificate]
  create_duration = "60s"
}

data "terracurl_request" "vault_init" {
  depends_on   = [time_sleep.wait_60_seconds]
  name         = "init"
  url          = "https://${local.fqdn}/v1/sys/init"
  method       = "PUT"
  request_body = <<EOF
{
    "secret_shares":0,
    "secret_threshold":0,
    "stored_shares":0,
    "pgp_keys":null,
    "recovery_shares":5,
    "recovery_threshold":3,
    "recovery_pgp_keys":null,
    "root_token_pgp_key":""
}
EOF

  skip_tls_verify = true
  response_codes = [
    200,
    204,
    400 # In case Vault is already inicialized
  ]

}

output "response" {
  sensitive = true
  value     = jsondecode(data.terracurl_request.vault_init.response)
}

# Create a Secret
resource "google_secret_manager_secret" "tokens" {
  secret_id = "vault-init-token"
  replication {
    auto {
    }
  }
}

# Add the Secret Value
resource "google_secret_manager_secret_version" "tokens" {
  secret      = google_secret_manager_secret.tokens.id
  secret_data = data.terracurl_request.vault_init.response
}