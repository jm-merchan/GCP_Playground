# Random suffix that will be added to resources created
resource "random_string" "tfe" {
  lower   = true
  special = false
  length  = 4
  upper   = false
}

# Create a global VPC if required
resource "google_compute_network" "global_vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "${var.region}-${var.vpc_name}-${random_string.tfe.result}"
  auto_create_subnetworks = false # Disable default subnets
}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.region}-subnet1-${random_string.tfe.result}"
  ip_cidr_range = var.subnet1-region
  region        = var.region
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference

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
  count         = var.create_vpc ? 1 : 0
  name          = "${var.region}-proxyonly-${random_string.tfe.result}"
  ip_cidr_range = var.subnet2-region
  region        = var.region
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.region}-custom-router-${random_string.tfe.result}"
  region  = var.region
  network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  count  = var.create_vpc ? 1 : 0
  name   = "${var.region}-custom-nat-${random_string.tfe.result}"
  router = google_compute_router.custom_router[0].name
  region = google_compute_router.custom_router[0].region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}


# Getting details for tfe active
data "kubernetes_service" "tfe" {
  depends_on = [helm_release.tfe_enterprise]
  metadata {
    name      = "terraform-enterprise"                    # Name of the service created by Helm
    namespace = kubernetes_namespace.tfe.metadata[0].name # Namespace where the Helm chart deployed the service
  }
}


# Create A record for External VIP API/UI
resource "google_dns_record_set" "vip" {
  count = var.expose == "External" ? 1 : 0
  name  = "tfe-${var.region}-${random_string.tfe.result}.${local.domain}."
  type  = "A"
  ttl   = 100

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [data.kubernetes_service.tfe.status[0].load_balancer[0].ingress[0].ip]
}


