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

  binary_data = {
    license = base64encode(var.vault_license)

  }
}

/*
# Config map for extra container with log-rotate
resource "kubernetes_config_map" "log-rotate" {
  metadata {
    name      = "logrotate-config"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "logrotate.conf" = <<EOF
        /vault/audit/vault.log {
        rotate 2
        size 1M
        missingok
        compress

        postrotate
            pkill -HUP vault
        endscript
    }

    EOF
  }
}
*/


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

# Deploy Vault Enterprise
resource "helm_release" "vault_enterprise" {
  count = var.vault_enterprise ? 1 : 0
  depends_on = [
    google_project_iam_member.vault_kms,
    # kubernetes_config_map.log-rotate
  ]
  name      = var.cluster-name
  namespace = kubernetes_namespace.vault.metadata[0].name
  chart     = "hashicorp/vault"
  version   = var.vault_helm_release

  values = [local.vault_user_data_ent]

}




/*
output "vault_lb_8200_internal" {
    description = "The internal loadbalancer ip address for port 8200 balancing across all nodes"
    value = data.kubernetes_service.vault_lb_8200.status[0].load_balancer[0].ingress[0].ip
}

output "vault_lb_8201_internal" {
    description = "The internal loadbalancer ip address for port 8201 balancing pointing to active node"
    value = data.kubernetes_service.vault_lb_8201.status[0].load_balancer[0].ingress[0].ip
}
*/