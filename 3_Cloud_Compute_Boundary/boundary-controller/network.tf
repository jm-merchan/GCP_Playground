# Create a global VPC
resource "google_compute_network" "global_vpc" {
  name                    = "${var.vpc_name}-${random_string.boundary.result}"
  auto_create_subnetworks = false # Disable default subnets

}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.region}-subnet1-${random_string.boundary.result}"
  ip_cidr_range = var.subnet1-region
  region        = var.region
  network       = google_compute_network.global_vpc.id
}
# Service Network
resource "google_compute_subnetwork" "subnet2" {
  name          = "${var.region}-privatevcp-${random_string.boundary.result}"
  ip_cidr_range = var.subnet2-region
  region        = var.region
  network       = google_compute_network.global_vpc.id
}
/*
resource "google_compute_subnetwork" "subnet3" {
  name          = "${var.region1}-subnet3-${random_string.boundary.result}"
  ip_cidr_range = var.subnet3-region1
  region        = var.region1
  network       = google_compute_network.global_vpc.id
}
*/
# Proxy only subnet
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "${var.region}-subnet-proxy-only-${random_string.boundary.result}"
  ip_cidr_range = var.subnet4-region
  region        = var.region
  network       = google_compute_network.global_vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  name    = "${var.region}-custom-router-${random_string.boundary.result}"
  region  = var.region
  network = google_compute_network.global_vpc.self_link
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  name   = "${var.region}-custom-nat-${random_string.boundary.result}"
  router = google_compute_router.custom_router.name
  region = google_compute_router.custom_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}

# Allow Traffic on port 9201 to BOUNDARY Public IPs
resource "google_compute_firewall" "cluster-worker" {
  name    = "${var.region}-clusterworker-firewall-${random_string.boundary.result}"
  network = google_compute_network.global_vpc.self_link

  description   = "The firewall which allows the ingress from Workers to BOUNDARY instances"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  # Using Boundary Controller Service Account
  target_service_accounts = [google_service_account.main.email]

  allow {
    protocol = "tcp"
    ports    = ["9201"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow traffic from Health Checks
resource "google_compute_firewall" "lb_healthchecks" {
  name                    = "${var.region}-lb-healthcheck-firewall-${random_string.boundary.result}"
  network                 = google_compute_network.global_vpc.self_link
  source_ranges           = var.networking_healthcheck_ips
  target_service_accounts = [google_service_account.main.email]
  description             = "Allow Healthcheck to BOUNDARY"
  direction               = "INGRESS"

  allow {
    protocol = "tcp"
    ports = [
      "9200",
      "9201",
      "9203",
      "22"

    ]
  }
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
  priority = "500"
}

# Allow all outbound traffic
resource "google_compute_firewall" "allow_boundary_outbound" {
  name        = "${var.region}-allow-boundary-outbound-${random_string.boundary.result}"
  network     = google_compute_network.global_vpc.id
  description = "Rule to allow all outbound traffic"
  allow {
    protocol = "tcp"
  }
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"] # Allow from any IP (internet)
}


# Allow traffic from designated network segments to VMS
resource "google_compute_firewall" "allow_boundary_all_external" {
  name    = "allow-boundary-all-${random_string.boundary.result}"
  network = google_compute_network.global_vpc.id
  allow {
    protocol = "tcp"
    ports = [
      "9200",
      "9201",
      "22"
    ]
  }
  source_ranges           = ["0.0.0.0/0"] # Allow from defined CIDR range
  target_service_accounts = [google_service_account.main.email]
  direction               = "INGRESS"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

/*
# Rule to allow all outbound traffic 
resource "google_compute_firewall" "allow_boundary_outbound" {
  name        = "allow-boundary-outbound-${random_string.boundary.result}"
  network     = google_compute_network.global_vpc.id
  description = "Rule to allow all outbound traffic"
  allow { # Allow ports for HTTP (80) and HTTPS (443)
    protocol = "tcp"
  }
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"] # Allow from any IP (internet)
  # source_tags = ["${var.resource_name_prefix}-boundary"]
}

# Rule to allow traffic between cluster nodes
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.resource_name_prefix}-boundary-allow-internal-${random_string.boundary.result}"
  network     = google_compute_network.global_vpc.id
  description = "Rule to allow traffic between cluster nodes on API and Cluster ports and PING"
  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }
  allow {
    protocol = "icmp"
  }
  source_tags = ["${var.resource_name_prefix}-boundary"]
  target_tags = ["${var.resource_name_prefix}-boundary"]
}

# Rule to allow traffic from internal subnets to BOUNDARY api
resource "google_compute_firewall" "lb_proxy" {
  name          = "${var.resource_name_prefix}-proxy-firewall-${random_string.boundary.result}"
  network       = google_compute_network.global_vpc.self_link
  source_ranges = [var.subnet1-region1, var.subnet2-region1, var.subnet3-region1, var.subnet4-region1]
  description   = "Rule to allow traffic from internal subnets to BOUNDARY api"
  target_tags   = ["${var.resource_name_prefix}-boundary"]

  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }
}

# Allow traffic from Health Checks
resource "google_compute_firewall" "lb_healthchecks" {
  name          = "${var.resource_name_prefix}-lb-healthcheck-firewall-${random_string.boundary.result}"
  network       = google_compute_network.global_vpc.self_link
  source_ranges = var.networking_healthcheck_ips
  target_tags   = ["${var.resource_name_prefix}-boundary"]
  description   = "Allow Healthcheck to BOUNDARY"

  allow {
    protocol = "tcp"
  }
}



*/