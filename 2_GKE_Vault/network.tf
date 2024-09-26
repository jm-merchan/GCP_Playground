# Random suffix that will be added to resources created
resource "random_string" "vault" {
  lower   = true
  special = false
  length  = 4
  upper   = false
}

# Create a global VPC if required
resource "google_compute_network" "global_vpc" {
  count                    = var.create_network ? 1 : 0
  name                     = "${var.vpc_name}-${random_string.vault.result}"
  auto_create_subnetworks  = false # Disable default subnets
  enable_ula_internal_ipv6 = true  # as in https://cloud.google.com/kubernetes-engine/docs/quickstarts/create-cluster-using-terraform?hl=es-419
}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  count         = var.create_network ? 1 : 0
  name          = "${var.region}-subnet1-${random_string.vault.result}"
  ip_cidr_range = var.subnet1-region
  region        = var.region
  network       = google_compute_network.global_vpc[0].id
  # stack_type       = "IPV4_IPV6"
  # ipv6_access_type = "EXTERNAL"

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "172.16.0.0/16"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "172.17.0.0/16"
  }
}


# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  count         = var.create_network ? 1 : 0
  name          = "${var.region}-proxyonly-${random_string.vault.result}"
  ip_cidr_range = var.subnet2-region
  region        = var.region
  network       = google_compute_network.global_vpc[0].id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  count   = var.create_network ? 1 : 0
  name    = "${var.region}-custom-router-${random_string.vault.result}"
  region  = var.region
  network = google_compute_network.global_vpc[0].id
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  count  = var.create_network ? 1 : 0
  name   = "${var.region}-custom-nat-${random_string.vault.result}"
  router = google_compute_router.custom_router[0].name
  region = google_compute_router.custom_router[0].region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}
