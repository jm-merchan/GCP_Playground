# Create Vault namespace
resource "kubernetes_namespace" "tfe" {
  metadata {
    name = var.k8s_namespace
  }
}

# Create Secret for license
resource "kubernetes_secret_v1" "license" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "images.releases.hashicorp.com" = {
          "username" = "terraform"
          "password" = var.tfe_license
          "auth"     = base64encode("terraform:${var.tfe_license}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "db_password" {
  metadata {
    name      = "db-password"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  data = {
    password = base64encode(var.db_password)
  }
}

resource "kubernetes_secret" "bucket_access" {
  metadata {
    name      = "bucket-access"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  binary_data = {
    access_id = base64encode(google_storage_hmac_key.tfe-s3-access.access_id)
    secret    = base64encode(google_storage_hmac_key.tfe-s3-access.secret)
  }
}


locals {
  tfe_domain = substr(data.google_dns_managed_zone.env_dns_zone.dns_name, 0, length(data.google_dns_managed_zone.env_dns_zone.dns_name) - 1)
}


resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

locals {
  # Templating Enterprise Yaml
  tfe_user_data = templatefile("${path.module}/templates/tfe-values.yaml.tpl",
    {
      certData                              = base64encode("${local.tfe_cert}\n${local.tfe_ca}")
      keyData                               = base64encode(local.tfe_key)
      caCertData                            = base64encode(local.tfe_ca)
      TFE_VERSION                           = var.tfe_version
      TFE_HOSTNAME                          = "tfe-${var.region}-${random_string.tfe.result}.${local.domain}"
      TFE_IACT_SUBNETS                      = "0.0.0.0/0"
      TFE_DATABASE_HOST                     = google_sql_database_instance.postgres_instance.private_ip_address
      TFE_DATABASE_NAME                     = "${var.instance_name}${random_string.tfe.result}"
      TFE_DATABASE_USER                     = var.db_username
      TFE_REDIS_HOST                        = "${google_redis_instance.my_memorystore_redis_tfe.host}:6379"
      TFE_OBJECT_STORAGE_GOOGLE_BUCKET      = google_storage_bucket.tfe_bucket.name
      TFE_OBJECT_STORAGE_GOOGLE_PROJECT     = var.project_id
      TFE_DATABASE_PASSWORD                 = var.db_password
      TFE_OBJECT_STORAGE_GOOGLE_CREDENTIALS = google_service_account_key.mykey.private_key
      TFE_LICENSE                           = var.tfe_license
      service_account                       = google_service_account.service_account.email
  })
}

# Deploy Vault Enterprise
resource "helm_release" "tfe_enterprise" {
  depends_on = [
    google_project_iam_member.tfe_kms,
    acme_certificate.certificate,
  ]
  name      = "tfe"
  namespace = kubernetes_namespace.tfe.metadata[0].name
  chart     = "hashicorp/terraform-enterprise"
  version   = var.tfe_helm_release
  values    = [local.tfe_user_data]
  wait      = true
  timeout   = 3600
}

