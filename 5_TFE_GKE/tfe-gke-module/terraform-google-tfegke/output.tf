output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.default.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.default.endpoint
  description = "GKE Cluster Host"
}

output "configure_kubectl" {
  description = "gcloud command to configure your kubeconfig once the cluster has been created"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.default.name} --region ${var.region} --project ${var.project_id}"
}

output "test" {
  value = local.tfe_domain
}

output "helm" {
  value     = helm_release.tfe_enterprise.values
  sensitive = true
}

# https://developer.hashicorp.com/terraform/enterprise/deploy/initial-admin-user
output "retrieve_initial_admin_creation_token" {
  value = "https://tfe-${var.region}-${random_string.tfe.result}.${local.domain}/admin/retrieve-iact"
}

output "create_initial_admin_user" {
  value = "https://tfe-${var.region}-${random_string.tfe.result}.${local.domain}/admin/account/new?token="

}