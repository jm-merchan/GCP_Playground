# Create Vault namespace
resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.k8s_namespace
  }
}

# Create Vault Certificate
resource "kubernetes_secret" "tls_secret" {
  metadata {
    name      = "vault-ha-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "vault.crt" = "${local.vault_cert}\n${local.vault_ca}"
    "vault.key" = local.vault_key
    "vault.ca"  = local.vault_ca
  }
}

# Create Secret for license
resource "kubernetes_secret" "license_secret" {
  count = var.vault_enterprise ? 1 : 0 # Create license if Vault Enterprise
  metadata {
    name      = "vault-ent-license"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    license = base64encode(var.vault_license)

  }
}



locals {
  # Templating Enterprise Yaml
  vault_user_data_ent = templatefile("${path.module}/templates/vault-ent-values.yaml.tpl",
    {
      crypto_key            = google_kms_crypto_key.vault_key.name
      key_ring              = google_kms_key_ring.key_ring.name
      leader_tls_servername = "${var.cluster-name}-${var.region}-${random_string.vault.result}.${local.domain}"
      location              = var.location
      project               = var.project_id
      vault_license         = var.vault_license
      vault_version         = local.vault_version
      number_nodes          = var.node_count
      namespace             = kubernetes_namespace.vault.metadata[0].name
      service_account       = google_service_account.service_account.email
    }
    # Templating CE Yaml

  )
}


resource "helm_release" "vault_enterprise" {
  count     = var.vault_enterprise ? 1 : 0
  depends_on = [ google_project_iam_member.vault_kms ]
  name      = var.cluster-name
  namespace = kubernetes_namespace.vault.metadata[0].name
  chart     = "hashicorp/vault"
  version   = var.vault_helm_release

  values = [local.vault_user_data_ent]

}