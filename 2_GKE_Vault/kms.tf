resource "google_kms_key_ring" "key_ring" {
  name     = "gke-kms-vault-keyring-${random_string.vault.result}"
  location = var.location
}

resource "google_kms_crypto_key" "vault_key" {
  name     = "gke-kms-vault-key-${random_string.vault.result}"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}