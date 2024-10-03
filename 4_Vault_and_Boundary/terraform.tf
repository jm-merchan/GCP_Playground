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


provider "acme" {
  server_url = local.acme_prod
}

resource "random_string" "string" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# Create a global VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.region}-${random_string.string.result}"
  auto_create_subnetworks = false # Disable default subnets
}

# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "${var.region}-proxy-only-${random_string.string.result}"
  ip_cidr_range = var.subnet-proxyOnly
  region        = var.region
  network       = google_compute_network.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  name    = "${var.region}-custom-router-${random_string.string.result}"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  name   = "${var.region}-custom-nat-${random_string.string.result}"
  router = google_compute_router.custom_router.name
  region = google_compute_router.custom_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}

module "boundary" {
  source              = "../3_Cloud_Compute_Boundary/boundary-controller-module/terraform-google-boundarycontroller"
  dns_zone_name_ext   = var.dns_zone_name_ext
  project_id          = var.project_id
  create_vpc          = false
  vpc_name            = google_compute_network.vpc.name
  region              = var.region
  location            = var.location
  machine_type        = var.machine_type
  boundary_version    = var.boundary_version
  email               = var.email
  cluster-name        = "boundary"
  boundary_license    = var.boundary_license
  node_count          = var.node_count
  boundary_enterprise = var.boundary_enterprise
  db_username         = var.db_username
  db_password         = var.db_password
  acme_prod            = var.acme_prod
}

module "vault1" {
  source               = "../2_GKE_Vault/vault-gke-module/terraform-google-vaultgke"
  create_vpc           = false
  subnet1-region       = "10.2.1.0/24"
  subnet2-region       = "10.2.10.0/24"
  email                = var.email
  project_id           = var.project_id
  dns_zone_name_ext    = var.dns_zone_name_ext
  cluster-name         = "vault"
  vault_version        = var.vault_version
  vault_enterprise     = true
  region               = var.region
  kmip_enable          = true
  vpc_name             = google_compute_network.vpc.name
  acme_prod            = var.acme_prod
  gke_autopilot_enable = true
  vault_license        = var.vault_license
  node_count           = var.node_count
  location             = var.location
  storage_location     = "EU"
}