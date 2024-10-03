# Create a global VPC
resource "google_compute_network" "global_vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "${var.region1}-${var.vpc_name}-${random_string.vault.result}"
  auto_create_subnetworks = false # Disable default subnets
}

# Create DNS Zone private
resource "google_dns_managed_zone" "private-zone" {
  name        = "${var.region1}-private-zone-${random_string.vault.result}"
  dns_name    = var.dns_zone_name_int
  description = "Example private DNS zone"

  visibility = "private"
  private_visibility_config {
    networks {
      network_url = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
    }
  }
}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.region1}-subnet1-${random_string.vault.result}"
  ip_cidr_range = var.subnet1-region1
  region        = var.region1
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
}

# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  count         = var.create_vpc ? 1 : 0
  name          = "${var.region1}-proxy-only-${random_string.vault.result}"
  ip_cidr_range = var.subnet4-region1
  region        = var.region1
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.region1}-custom-router-${random_string.vault.result}"
  region  = var.region1
  network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  count  = var.create_vpc ? 1 : 0
  name   = "${var.region1}-custom-nat-${random_string.vault.result}"
  router = google_compute_router.custom_router[0].name
  region = google_compute_router.custom_router[0].region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}


# Allow traffic from designated network segments to VMS
resource "google_compute_firewall" "allow_vault_all_external" {
  name    = "${var.region1}-allow-vault-all-${random_string.vault.result}"
  network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  description = "Allow traffic to API and Cluster port from designated segments"
  allow {
    protocol = "tcp"
    ports = [
      "8200",
      "8201",
    ]
  }
  source_ranges = [var.allowed_networks] # Allow from defined CIDR range
  target_service_accounts = [google_service_account.main.email]
  direction     = "INGRESS"

    log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Rule to allow all outbound traffic 
resource "google_compute_firewall" "allow_vault_outbound" {
  name        = "${var.region1}-allow-vault-outbound-${random_string.vault.result}"
  network     = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  description = "Rule to allow all outbound traffic"
  allow { # Allow ports for HTTP (80) and HTTPS (443)
    protocol = "tcp"
  }
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"] # Allow from any IP (internet)
  # source_tags = ["${var.resource_name_prefix}-${var.region1}-${random_string.vault.result}"]

    log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Rule to allow traffic between cluster nodes
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.region1}-vault-allow-internal-${random_string.vault.result}"
  network     = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  description = "Rule to allow traffic between cluster nodes on API and Cluster ports and PING"
  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }
  allow {
    protocol = "icmp"
  }
  source_service_accounts = [google_service_account.main.email]
  target_service_accounts = [google_service_account.main.email]

    log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Rule to allow traffic from internal subnets to Vault api
resource "google_compute_firewall" "lb_proxy" {
  name          = "${var.region1}-proxy-firewall-${random_string.vault.result}"
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  source_ranges = [var.subnet1-region1, var.subnet4-region1]
  description   = "Rule to allow traffic from internal subnets to Vault api, including loadbalancer"
  target_service_accounts = [google_service_account.main.email]

  priority = "100"

  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow traffic from Health Checks
resource "google_compute_firewall" "lb_healthchecks" {
  name          = "${var.region1}-lb-healthcheck-firewall-${random_string.vault.result}"
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  source_ranges = var.networking_healthcheck_ips
  target_service_accounts = [google_service_account.main.email]
  description   = "Allow Healthcheck to Vault"

  allow {
    protocol = "tcp"
  }

    log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow SSH from my IP to Vault Public IPs
resource "google_compute_firewall" "ssh" {
  name    = "${var.region1}-ssh-firewall-${random_string.vault.result}"
  network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  description   = "The firewall which allows the ingress of SSH traffic to Vault instances"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.main.email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

    log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
} 