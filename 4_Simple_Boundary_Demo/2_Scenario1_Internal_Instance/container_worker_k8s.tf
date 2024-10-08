provider "kubernetes" {
  # config_path = "~/.kube/config"

  host                   = data.terraform_remote_state.local_backend.outputs.kubernetes_cluster["host"]
  token                  = data.terraform_remote_state.local_backend.outputs.kubernetes_cluster["token"]
  cluster_ca_certificate = data.terraform_remote_state.local_backend.outputs.kubernetes_cluster["cluster_ca_certificate"]

  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

locals {
  boundary = "boundary"
}

# Create Namespace
resource "kubernetes_namespace" "boundary" {
  metadata {
    name = local.boundary
  }
}

# Service Account for Boundary mapped to GCP Service acccount
resource "kubernetes_service_account" "boundary" {
  metadata {
    name      = local.boundary
    namespace = kubernetes_namespace.boundary.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" : "${google_service_account.worker.email}"
    }
  }
}

# Add KMS access to Boundary service account running in Worker POD
resource "google_project_iam_member" "workload_identity-role" {
  project = var.project_id
  role    = google_project_iam_custom_role.kms_role.name
  member  = "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.boundary.metadata[0].name}/${local.boundary}]"
}

resource "boundary_worker" "egress_pki_worker" {
  count                       = var.worker_mode == "pki" ? 1 : 0
  scope_id                    = "global"
  name                        = "pki-worker2-egress-${random_string.string.result}"
  worker_generated_auth_token = ""

}

locals {
  boundary_user_data_k8s_kms = templatefile("${path.module}/templates/configMap_kms.yaml.tpl",
    {
      # activation_token = boundary_worker.ingress_pki_worker.controller_generated_activation_token
      upstream         = var.worker_mode == "kms" ? google_compute_instance.worker_kms[0].network_interface[0].network_ip : ""
      worker_type      = "worker-k8s"
      key_ring         = data.terraform_remote_state.local_backend.outputs.key_ring
      cryto_key_worker = data.terraform_remote_state.local_backend.outputs.crypto_key_worker
      project          = var.project_id
      location         = "global"
      function         = "downstream"
      instance_id      = "boundary-pod-worker-${random_string.string.result}"
    }
  )
  boundary_user_data_k8s_pki = templatefile("${path.module}/templates/configMap_pki.yaml.tpl",
    {
      
      upstream         = var.worker_mode == "pki" ? google_compute_instance.worker_pki[0].network_interface[0].network_ip : ""
      worker_type      = "worker-k8s"
      activation_token = var.worker_mode == "pki" ? boundary_worker.egress_pki_worker[0].controller_generated_activation_token : ""
      project          = var.project_id
      location         = "global"
      function         = "downstream"
      public_addr       = kubernetes_service.master.status[0].load_balancer[0].ingress[0].ip
    }
  )
}


# Boundary Worker Config Map if using KMS
resource "kubernetes_config_map" "boundary_kms" {
  count = var.worker_mode == "kms" ? 1 : 0
  metadata {
    name      = local.boundary
    namespace = kubernetes_namespace.boundary.metadata[0].name
  }

  data = {
    "worker.hcl" = local.boundary_user_data_k8s_kms
  }
}

# Boundary Worker Config Map if using PKI
resource "kubernetes_config_map" "boundary_pki" {
  count = var.worker_mode == "pki" ? 1 : 0
  metadata {
    name      = local.boundary
    namespace = kubernetes_namespace.boundary.metadata[0].name
  }

  data = {
    "worker.hcl" = local.boundary_user_data_k8s_pki
  }
}


# Boundary Worker Deployment for KMS
resource "kubernetes_deployment_v1" "boundary" {
  count = var.worker_mode == "kms" ? 1 : 0
  metadata {
    name      = "worker-kms-${local.boundary}"
    namespace = kubernetes_namespace.boundary.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = local.boundary
      }
    }

    template {
      metadata {
        labels = {
          app = local.boundary
        }
      }

      spec {
        service_account_name = kubernetes_service_account.boundary.metadata[0].name

        volume {
          name = "boundary-worker-configuration-volume"
          config_map {
            name         = kubernetes_config_map.boundary_kms[0].metadata[0].name
            default_mode = "0644" # Octal for 420
          }
        }

        container {
          image = "josemerchan/boundary-worker:0.0.4"
          name  = local.boundary

          port {
            container_port = 9202
            name           = "proxy"
          }
          port {
            container_port = 9203
            name           = "ops"
          }

          image_pull_policy = "Always"
          volume_mount {
            name       = "boundary-worker-configuration-volume"
            mount_path = "/opt/boundary/config/"
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = "ops"
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = "ops"
              scheme = "HTTP"
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }

    }
  }
}



# Service for stateful set
resource "kubernetes_service" "master" {
  metadata {
    name      = local.boundary
    namespace = kubernetes_namespace.boundary.metadata[0].name
    annotations = {
      "cloud.google.com/load-balancer-type" : "Internal"
    }
  }

  spec {
    type = "LoadBalancer"
    port {
      name        = "proxy"
      port        = 9202
      target_port = 9202
    }

    selector = {
      app = local.boundary
    }
  }
}


# Boundary Worker Deployment for PKI
resource "kubernetes_stateful_set_v1" "boundary" {
  count = var.worker_mode == "pki" ? 1 : 0
  metadata {
    name      = "worker-pki-${local.boundary}"
    namespace = kubernetes_namespace.boundary.metadata[0].name
  }
  spec {
    service_name = kubernetes_service.master.metadata[0].name
    selector {
      match_labels = {
        app = local.boundary
      }
    }

    volume_claim_template {
      metadata {
        name = "boundary-worker-storage-volume"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard-rwo"
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }

    template {
      metadata {
        labels = {
          app = local.boundary
        }
      }

      spec {
        service_account_name = kubernetes_service_account.boundary.metadata[0].name
        # Security context to set the fsGroup for PVC permissions

   
        security_context {
          run_as_user = 1000 # Assuming the boundary user has UID 1000
          fs_group    = 1000 # This ensures the boundary user can write to the mounted volume
        }
 
        volume {
          name = "boundary-worker-configuration-volume"
          config_map {
            name         = kubernetes_config_map.boundary_pki[0].metadata[0].name
            default_mode = "0644"
          }
        }

        volume {
          name = "boundary-worker-storage-volume"
          persistent_volume_claim {
            claim_name = "boundary-worker-storage-volume"
          }
        }

        container {
          image = "josemerchan/boundary-worker:0.0.4"
          name  = local.boundary
          # command = [ "sh", "-c", "sleep 84000s" ]

          port {
            container_port = 9202
            name           = "proxy"
          }
          port {
            container_port = 9203
            name           = "ops"
          }

          image_pull_policy = "Always"

          volume_mount {
            name       = "boundary-worker-configuration-volume"
            mount_path = "/opt/boundary/config/"
          }

          volume_mount {
            name       = "boundary-worker-storage-volume"
            mount_path = "/opt/boundary/data/"
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = "ops"
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = "ops"
              scheme = "HTTP"
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }

    }
  }
}