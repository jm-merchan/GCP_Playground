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

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    /*
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    */
  }
}


provider "google" {
  project = var.project_id
}

resource "random_string" "string" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# Create a global VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.region1}-${var.vpc_name}-${random_string.string.result}"
  auto_create_subnetworks = false # Disable default subnets
}

# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "${var.region1}-proxy-only-${random_string.string.result}"
  ip_cidr_range = var.subnet4-region1
  region        = var.region1
  network       = google_compute_network.vpc.id 
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  name    = "${var.region1}-custom-router-${random_string.string.result}"
  region  = var.region1
  network =google_compute_network.vpc.id 
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  name   = "${var.region1}-custom-nat-${random_string.string.result}"
  router = google_compute_router.custom_router.name
  region = google_compute_router.custom_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}

provider "acme" {
  server_url = local.acme_prod
  # server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # Testing
  # server_url = "https://acme-v02.api.letsencrypt.org/directory" # Production
}

module "vault1" {
  source               = "./terraform-google-vaultcluster"
  dns_zone_name_ext    = var.dns_zone_name_ext
  project_id           = var.project_id
  vpc_name             = "${var.region1}-${var.vpc_name}-${random_string.string.result}"
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
  create_vpc           = false
  subnet1-region1      = "10.1.1.0/24"
  subnet4-region1      = "10.1.10.0/24"
}
/*
module "vault2" {
  source               = "./terraform-google-vaultcluster"
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
*/