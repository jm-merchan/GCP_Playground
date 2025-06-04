terraform {
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "6.3.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = "2.26.0"
    }
  }
}


provider "google" {
  project = var.project_id
}

/*
provider "google-beta" {
  project = var.project_id
}
*/

provider "acme" {
  server_url = local.acme_prod
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # Testing
  # server_url = "https://acme-v02.api.letsencrypt.org/directory" # Production
}

module "tfe" {
  source               = "./terraform-google-tfe-gke"
}
