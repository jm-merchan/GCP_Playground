# Create a global VPC
resource "google_compute_network" "global_vpc" {
  name                    = "${var.vpc_name}-${random_string.vault.result}"
  auto_create_subnetworks = false # Disable default subnets
}

# Create DNS Zone private
resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone"
  dns_name    = var.dns_zone_name_int
  description = "Example private DNS zone"

  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.global_vpc.self_link
    }
  }
}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.region1}-subnet1-${random_string.vault.result}"
  ip_cidr_range = var.subnet1-region1
  region        = var.region1
  network       = google_compute_network.global_vpc.id
}

resource "google_compute_subnetwork" "subnet2" {
  name          = "${var.region1}-subnet2-${random_string.vault.result}"
  ip_cidr_range = var.subnet2-region1
  region        = var.region1
  network       = google_compute_network.global_vpc.id
}

resource "google_compute_subnetwork" "subnet3" {
  name          = "${var.region1}-subnet3-${random_string.vault.result}"
  ip_cidr_range = var.subnet3-region1
  region        = var.region1
  network       = google_compute_network.global_vpc.id
}

# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  # name          = "${var.region1}-subnet4-${random_string.vault.result}"
  name          = "${var.resource_name_prefix}-subnet4-${random_string.vault.result}"
  ip_cidr_range = var.subnet4-region1
  region        = var.region1
  network       = google_compute_network.global_vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  name    = "custom-router-${random_string.vault.result}"
  region  = var.region1
  network = google_compute_network.global_vpc.self_link
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  name   = "custom-nat-${random_string.vault.result}"
  router = google_compute_router.custom_router.name
  region = google_compute_router.custom_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}


# Allow traffic from designated network segments to VMS
resource "google_compute_firewall" "allow_vault_all_external" {
  name    = "allow-vault-all-${random_string.vault.result}"
  network = google_compute_network.global_vpc.id
  allow {
    protocol = "tcp"
    ports = [
      "8200",
      "8201",
    ]
  }
  source_ranges = [var.allowed_networks] # Allow from defined CIDR range
  target_tags   = ["${var.resource_name_prefix}-vault"]
  direction     = "INGRESS"
}

# Rule to allow all outbound traffic 
resource "google_compute_firewall" "allow_vault_outbound" {
  name        = "allow-vault-outbound-${random_string.vault.result}"
  network     = google_compute_network.global_vpc.id
  description = "Rule to allow all outbound traffic"
  allow { # Allow ports for HTTP (80) and HTTPS (443)
    protocol = "tcp"
  }
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"] # Allow from any IP (internet)
  # source_tags = ["${var.resource_name_prefix}-vault"]
}

# Rule to allow traffic between cluster nodes
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.resource_name_prefix}-vault-allow-internal-${random_string.vault.result}"
  network     = google_compute_network.global_vpc.id
  description = "Rule to allow traffic between cluster nodes on API and Cluster ports and PING"
  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }
  allow {
    protocol = "icmp"
  }
  source_tags = ["${var.resource_name_prefix}-vault"]
  target_tags = ["${var.resource_name_prefix}-vault"]
}

# Rule to allow traffic from internal subnets to Vault api
resource "google_compute_firewall" "lb_proxy" {
  name          = "${var.resource_name_prefix}-proxy-firewall-${random_string.vault.result}"
  network       = google_compute_network.global_vpc.self_link
  source_ranges = [var.subnet1-region1, var.subnet2-region1, var.subnet3-region1, var.subnet4-region1]
  description   = "Rule to allow traffic from internal subnets to Vault api"
  target_tags   = ["${var.resource_name_prefix}-vault"]

  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }
}

# Allow traffic from Health Checks
resource "google_compute_firewall" "lb_healthchecks" {
  name          = "${var.resource_name_prefix}-lb-healthcheck-firewall-${random_string.vault.result}"
  network       = google_compute_network.global_vpc.self_link
  source_ranges = var.networking_healthcheck_ips
  target_tags   = ["${var.resource_name_prefix}-vault"]
  description   = "Allow Healthcheck to Vault"

  allow {
    protocol = "tcp"
  }
}

# Allow SSH from my IP to Vault Public IPs
resource "google_compute_firewall" "ssh" {
  name    = "${var.resource_name_prefix}-ssh-firewall-${random_string.vault.result}"
  network = google_compute_network.global_vpc.self_link

  description   = "The firewall which allows the ingress of SSH traffic to Vault instances"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.resource_name_prefix}-vault"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
} 