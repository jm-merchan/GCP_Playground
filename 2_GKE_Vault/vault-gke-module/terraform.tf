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

module "vault1" {
  source               = "./terraform-google-vaultgke"
  email                = var.email
  project_id           = var.project_id
  dns_zone_name_ext    = var.dns_zone_name_ext
  cluster-name         = "vault-primary"
  vault_version        = var.vault_version
  vault_enterprise     = var.vault_enterprise
  region               = var.region
  kmip_enable          = true
  vpc_name             = "vpc1"
  acme_prod            = true
  gke_autopilot_enable = true
  vault_license        = var.vault_license
  node_count           = 5
  location             = "global"
  storage_location     = "EU"
  create_vpc            = true
  subnet1-region       = "10.2.1.0/24"
  subnet2-region       = "10.2.10.0/24"
}


module "vault2" {
  source               = "./terraform-google-vaultgke"
  email                = var.email
  project_id           = var.project_id
  dns_zone_name_ext    = var.dns_zone_name_ext
  cluster-name         = "vault-secondary"
  vault_version        = var.vault_version
  vault_enterprise = var.vault_enterprise
  region               = var.region
  kmip_enable          = true
  vpc_name             = "vpc2"
  acme_prod            = true
  gke_autopilot_enable = true
  vault_license        = var.vault_license
  node_count           = 5
  location             = "global"
  storage_location     = "EU"
  create_vpc = true
}
