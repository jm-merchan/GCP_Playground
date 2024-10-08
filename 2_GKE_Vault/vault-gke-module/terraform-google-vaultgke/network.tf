# Random suffix that will be added to resources created
resource "random_string" "vault" {
  lower   = true
  special = false
  length  = 4
  upper   = false
}

# Create a global VPC if required
resource "google_compute_network" "global_vpc" {
  count                    = var.create_vpc ? 1 : 0
  name                     = "${var.region}-${var.vpc_name}-${random_string.vault.result}"
  auto_create_subnetworks  = false # Disable default subnets
}

# Create subnets in a given region
resource "google_compute_subnetwork" "subnet1" {
  name          = "${var.region}-subnet1-${random_string.vault.result}"
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
  count  = var.create_vpc ? 1 : 0
  name          = "${var.region}-proxyonly-${random_string.vault.result}"
  ip_cidr_range = var.subnet2-region
  region        = var.region
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Create a Cloud Router
resource "google_compute_router" "custom_router" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.region}-custom-router-${random_string.vault.result}"
  region  = var.region
  network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
}

# Configure Cloud NAT on the Cloud Router
resource "google_compute_router_nat" "custom_nat" {
  count  = var.create_vpc ? 1 : 0
  name   = "${var.region}-custom-nat-${random_string.vault.result}"
  router = google_compute_router.custom_router[0].name
  region = google_compute_router.custom_router[0].region

  nat_ip_allocate_option             = "AUTO_ONLY"                     # Google will automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Allow all internal VMs to use this NAT for outbound traffic
}

# Getting details for vault active
data "kubernetes_service" "vault_lb_8201" {
  depends_on = [helm_release.vault_enterprise, helm_release.vault_community]
  metadata {
    name      = "${var.cluster-name}-active"                # Name of the service created by Helm
    namespace = kubernetes_namespace.vault.metadata[0].name # Namespace where the Helm chart deployed the service
  }
}

# Getting details for vault service
data "kubernetes_service" "vault_lb_8200" {
  depends_on = [helm_release.vault_enterprise, helm_release.vault_community]
  metadata {
    name      = var.cluster-name                            # Name of the service created by Helm
    namespace = kubernetes_namespace.vault.metadata[0].name # Namespace where the Helm chart deployed the service
  }
}

# Getting details for kmip service
data "kubernetes_service" "vault_lb_5696" {
  depends_on = [helm_release.vault_enterprise, kubernetes_service.kmip]
  metadata {
    name      = "${var.cluster-name}-kmip"                  # Name of the service created by Helm
    namespace = kubernetes_namespace.vault.metadata[0].name # Namespace where the Helm chart deployed the service
  }
}

# Create A record for External VIP API/UI
resource "google_dns_record_set" "vip" {
  count = var.expose == "External" ? 1:0
  name = "${var.cluster-name}-${var.region}-${random_string.vault.result}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [data.kubernetes_service.vault_lb_8200.status[0].load_balancer[0].ingress[0].ip]
}

# Create A record for External VIP CLUSTER PORT
resource "google_dns_record_set" "vip_cluster_port" {
  count = var.expose == "External" ? 1:0
  name = "${var.cluster-name}-clusterport-${var.region}-${random_string.vault.result}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [data.kubernetes_service.vault_lb_8201.status[0].load_balancer[0].ingress[0].ip]
}

# Create A record for External VIP KMIP
resource "google_dns_record_set" "vip_kmip" {
  count = (var.kmip_enable && var.vault_enterprise && var.expose == "External") ? 1 : 0
  name  = "${var.cluster-name}-${var.region}-kmip-${random_string.vault.result}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [data.kubernetes_service.vault_lb_5696.status[0].load_balancer[0].ingress[0].ip]
}