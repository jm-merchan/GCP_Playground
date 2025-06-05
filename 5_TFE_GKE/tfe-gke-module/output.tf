output "project_id" {
  value       = module.tfe.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = module.tfe.kubernetes_cluster_name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = module.tfe.kubernetes_cluster_host
  description = "GKE Cluster Host"
}

output "configure_kubectl" {
  description = "gcloud command to configure your kubeconfig once the cluster has been created"
  value       = module.tfe.configure_kubectl
}

output "helm" {
  value     = module.tfe.helm
  description = "Helm release values for TFE Enterprise"
  sensitive = true
}

# https://developer.hashicorp.com/terraform/enterprise/deploy/initial-admin-user
output "retrieve_initial_admin_creation_token" {
  value = module.tfe.retrieve_initial_admin_creation_token
  description = "URL to retrieve the initial admin creation token for TFE"
}

output "create_initial_admin_user" {
  value = module.tfe.create_initial_admin_user
  description = "URL to create the initial admin user for TFE. Attach the token from the previous output to this URL."
}