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

module "boundary" {
  source              = "./terraform-google-boundarycontroller"
  dns_zone_name_ext   = var.dns_zone_name_ext
  project_id          = var.project_id
  create_vpc          = false
  vpc_name            = "europe-west1-demo-vpc-lxj9"
  region              = var.region
  location            = var.location
  machine_type        = var.machine_type
  boundary_version    = var.boundary_version
  email               = var.email
  cluster-name        = var.cluster-name
  boundary_license    = var.boundary_license
  node_count          = var.node_count
  boundary_enterprise = true
  db_username         = var.db_username
  db_password         = var.db_password
}
