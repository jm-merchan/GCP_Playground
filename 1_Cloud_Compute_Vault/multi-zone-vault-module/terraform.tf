terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
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

provider "google-beta" {
  project = var.project_id
}

provider "acme" {
  server_url = local.acme_prod
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # Testing
  # server_url = "https://acme-v02.api.letsencrypt.org/directory" # Production
}

module "vault" {
  source               = "./vault-module"
  dns_zone_name_ext    = var.dns_zone_name_ext
  project_id           = var.project_id
  vpc_name             = var.vpc_name
  region1              = var.region1
  location             = var.location
  machine_type         = var.machine_type
  vault_version        = var.vault_version
  resource_name_prefix = var.resource_name_prefix
  email                = var.email
  cluster-name         = var.cluster-name
  vault_license        = var.vault_license
  node_count           = var.node_count
  allowed_networks     = var.allowed_networks
  vault_enterprise     = true
  kmip_enable          = true
  storage_location     = var.storage_location
}

module "vault2" {
  source               = "./vault-module"
  dns_zone_name_ext    = var.dns_zone_name_ext
  project_id           = var.project_id
  vpc_name             = var.vpc_name
  region1              = var.region1
  location             = var.location
  machine_type         = var.machine_type
  vault_version        = var.vault_version
  resource_name_prefix = "demo2"
  email                = var.email
  cluster-name         = "vault-eu-secondary"
  vault_license        = var.vault_license
  node_count           = var.node_count
  allowed_networks     = var.allowed_networks
  vault_enterprise     = true
  kmip_enable          = true
  storage_location     = var.storage_location
}