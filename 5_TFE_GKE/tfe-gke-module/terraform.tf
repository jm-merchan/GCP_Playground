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
  source            = "./terraform-google-tfegke"
  dns_zone_name_ext = var.dns_zone_name_ext
  project_id        = var.project_id
  vpc_name          = var.vpc_name
  region            = var.region
  location          = var.location
  email             = var.email
  instance_name     = var.instance_name
  acme_prod         = var.acme_prod
  tfe_license       = var.tfe_license
  node_count        = var.node_count
  db_username       = var.db_username
  db_password       = var.db_password
  create_network    = var.create_network
  expose            = var.expose
  tfe_version       = var.tfe_version

}
