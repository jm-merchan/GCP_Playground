terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.15"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
  }
}

# Declare the provider for the HashiCorp Boundary resource to be managed by Terraform
provider "boundary" {
  # Use variables to provide values for the provider configuration
  addr                   = ""
  auth_method_id         = var.authmethod
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

provider "google" {
  project = var.project_id
}

provider "vault" {

}

# Remote Backend to obtain VPC details 
data "terraform_remote_state" "local_backend" {
  backend = "local"

  config = {
    path = "../1_Infra_internal_vault_internal_boundary/terraform.tfstate"
  }
}

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