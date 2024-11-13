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

# Create KMIP loadbalancer
resource "kubernetes_service" "kmip" {
  depends_on = [helm_release.vault_enterprise]
  count      = (var.kmip_enable && var.vault_enterprise) ? 1 : 0
  metadata {
    name      = "${var.cluster-name}-kmip"
    namespace = kubernetes_namespace.vault.metadata[0].name

    labels = {
      "app.kubernetes.io/instance" = var.cluster-name
      "app.kubernetes.io/name"     = "vault"
    }

    annotations = {
      "cloud.google.com/load-balancer-type" = var.expose
      "meta.helm.sh/release-name"           = var.cluster-name
      "meta.helm.sh/release-namespace"      = kubernetes_namespace.vault.metadata[0].name
    }

  }

  spec {
    port {
      name        = "kmip"
      protocol    = "TCP"
      port        = 5696
      target_port = 5696
    }

    selector = {
      "app.kubernetes.io/instance" = var.cluster-name
      "app.kubernetes.io/name"     = "vault"
      component                    = "server"
    }

    type                              = "LoadBalancer"
    session_affinity                  = "ClientIP"
    external_traffic_policy           = "Local"
    publish_not_ready_addresses       = true
    ip_families                       = ["IPv4"]
    ip_family_policy                  = "SingleStack"
    allocate_load_balancer_node_ports = true
    internal_traffic_policy           = "Cluster"
  }
}


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
      expose                = var.expose
    })
    # Templating CE Yaml
  vault_user_data_ce = templatefile("${path.module}/templates/vault-ce-values.yaml.tpl",
    {
      crypto_key            = google_kms_crypto_key.vault_key.name
      key_ring              = google_kms_key_ring.key_ring.name
      leader_tls_servername = "${var.cluster-name}-${var.region}-${random_string.vault.result}.${local.domain}"
      location              = var.location
      project               = var.project_id
      vault_version         = local.vault_version
      number_nodes          = var.node_count
      namespace             = kubernetes_namespace.vault.metadata[0].name
      service_account       = google_service_account.service_account.email
      expose                = var.expose
    }
  )
}

# Deploy Vault Enterprise
resource "helm_release" "vault_enterprise" {
  count = var.vault_enterprise ? 1 : 0
  depends_on = [
    google_project_iam_member.vault_kms,
    kubernetes_config_map.log-rotate,
    acme_certificate.certificate,
    kubernetes_secret.tls_secret 
  ]
  name      = var.cluster-name
  namespace = kubernetes_namespace.vault.metadata[0].name
  chart     = "hashicorp/vault"
  version   = var.vault_helm_release
  values = [local.vault_user_data_ent]
}

# Deploy Vault Community
resource "helm_release" "vault_community" {
  count = var.vault_enterprise ? 0 : 1
  depends_on = [
    google_project_iam_member.vault_kms,
    kubernetes_config_map.log-rotate,
    acme_certificate.certificate,
    kubernetes_secret.tls_secret 
  ]
  name      = var.cluster-name
  namespace = kubernetes_namespace.vault.metadata[0].name
  chart     = "hashicorp/vault"
  version   = var.vault_helm_release
  values = [local.vault_user_data_ce]
}
