# Private Endpoint for internal load balancer
resource "google_compute_address" "internal" {
  name         = "${var.resource_name_prefix}-vault-internal-lb"
  region       = var.region1
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.subnet1.id
}

resource "google_compute_address" "internal2" {
  name         = "${var.resource_name_prefix}-vault-internal-lb2"
  region       = var.region1
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.subnet1.id
}

# Public Endpoint for public load balancer
resource "google_compute_address" "public" {
  name         = "${var.resource_name_prefix}-vault-public-lb"
  region       = var.region1
  address_type = "EXTERNAL"
  # purpose      = "GCE_ENDPOINT"
  # subnetwork   = google_compute_subnetwork.subnet1.id
}

# Health check to load balance against all nodes
resource "google_compute_region_health_check" "lb" {
  name               = "${var.resource_name_prefix}-vault-interal-lb-${var.region1}"
  region             = var.region1
  check_interval_sec = 30
  description        = "The health check of the internal load balancer for Vault"
  timeout_sec        = 4

  https_health_check {
    port         = 8200
    request_path = var.vault_lb_health_check
  }
}

# Health check to detect active node
resource "google_compute_region_health_check" "lb_cluster" {
  name               = "${var.resource_name_prefix}-vault-interal-lb-cluster-${var.region1}"
  region             = var.region1
  check_interval_sec = 30
  description        = "The health check of the internal load balancer for Vault"
  timeout_sec        = 4

  https_health_check {
    port         = 8200
    request_path = var.vault_lb_cluster_health_check
  }
}

resource "google_compute_region_backend_service" "lb" {
  health_checks         = [google_compute_region_health_check.lb.self_link]
  name                  = "${var.resource_name_prefix}-vault-internal-lb-api"
  region                = var.region1
  description           = "The backend service of the internal load balancer for Vault"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_name             = "https"
  protocol              = "HTTPS"
  timeout_sec           = 10

  backend {
    group = google_compute_region_instance_group_manager.vault.instance_group

    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}

# External Backend for Vault on port 8200
resource "google_compute_region_backend_service" "lb-ext-api" {
  health_checks         = [google_compute_region_health_check.lb.self_link]
  name                  = "${var.resource_name_prefix}-vault-external-lb-api"
  region                = var.region1
  description           = "The backend service of the external load balancer for Vault"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "https"
  protocol              = "TCP"
  timeout_sec           = 10

  backend {
    group = google_compute_region_instance_group_manager.vault.instance_group

    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}

# External Backend for Vault on port 8201
resource "google_compute_region_backend_service" "lb-ext-cluster" {
  health_checks         = [google_compute_region_health_check.lb_cluster.self_link]
  name                  = "${var.resource_name_prefix}-vault-external-lb-cluster"
  region                = var.region1
  description           = "The backend service of the external load balancer for Vault on port 8201"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "cluster" # The port 8201 as defined in the MIG, should be changed to variable
  protocol              = "TCP"
  timeout_sec           = 10

  backend {
    group = google_compute_region_instance_group_manager.vault.instance_group

    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}


resource "google_compute_region_url_map" "lb" {
  default_service = google_compute_region_backend_service.lb.self_link
  name            = "${var.resource_name_prefix}-vault-internal-lb"
  region          = var.region1

  description = "The URL map of the internal load balancer for Vault"
}

data "google_dns_managed_zone" "env_dns_zone" {
  name = var.dns_zone_name_ext
}
# Create A record for External VIP
resource "google_dns_record_set" "vip" {
  name = "${var.cluster-name}-${var.region1}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [google_compute_address.public.address]
}

# Regional SSL Certificate with the content of the Let's Encrypt signed server previously created
resource "google_compute_region_ssl_certificate" "vault_ssl_cert" {
  name   = "${var.resource_name_prefix}-vault-ssl-cert"
  region = var.region1
  # private_key = tls_private_key.server.private_key_pem
  private_key = local.vault_key
  # certificate = tls_locally_signed_cert.server.cert_pem # Path to your certificate
  certificate = local.vault_cert
}

# Frontend configuration for internal LB on port 8200
resource "google_compute_region_target_https_proxy" "lb" {
  name             = "${var.resource_name_prefix}-vault-internal-lb-${var.region1}"
  region           = var.region1
  ssl_certificates = [google_compute_region_ssl_certificate.vault_ssl_cert.self_link]
  url_map          = google_compute_region_url_map.lb.self_link

  description = "The target HTTPS proxy of the internal load balancer for Vault"
}

# Frontend configuration for external LB on port 8200
resource "google_compute_region_target_tcp_proxy" "ext-lb-api" {
  name            = "${var.resource_name_prefix}-vault-external-lb-api-${var.region1}"
  region          = var.region1
  backend_service = google_compute_region_backend_service.lb-ext-api.id
  description     = "The target TCP proxy of the external load balancer for Vault api port"
}

# Frontend configuration for external LB on port 8201
resource "google_compute_region_target_tcp_proxy" "ext-lb-cluster" {
  name            = "${var.resource_name_prefix}-vault-external-lb-cluster-${var.region1}"
  region          = var.region1
  backend_service = google_compute_region_backend_service.lb-ext-cluster.id
  description     = "The target TCP proxy of the external load balancer for Vault cluster port"
}


# Port 443 route for internal load balancer with HTTPS interception
resource "google_compute_forwarding_rule" "lb1" {
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  name                  = "${var.resource_name_prefix}-vault-internal-lb1"
  region                = var.region1
  ip_address            = google_compute_address.internal.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 443
  network               = google_compute_network.global_vpc.id
  target                = google_compute_region_target_https_proxy.lb.id
  subnetwork            = google_compute_subnetwork.subnet1.id # same subnet as VIP
}

# Port 8200  route for internal load balancer with HTTPS interception
resource "google_compute_forwarding_rule" "lb2" {
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  name                  = "${var.resource_name_prefix}-vault-internal-lb2"
  region                = var.region1
  ip_address            = google_compute_address.internal2.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 8200
  network               = google_compute_network.global_vpc.id
  target                = google_compute_region_target_https_proxy.lb.id
  subnetwork            = google_compute_subnetwork.subnet1.id # same subnet as VIP
}

# Port 8200  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb1" {
  name                  = "${var.resource_name_prefix}-vault-external-lb1"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 8200
  network               = google_compute_network.global_vpc.id
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}

# Port 443  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb2" {
  name                  = "${var.resource_name_prefix}-vault-external-lb2"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 443
  network               = google_compute_network.global_vpc.id
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}

# Port 8201  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb3" {
  name                  = "${var.resource_name_prefix}-vault-external-lb3"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 8201
  network               = google_compute_network.global_vpc.id
  target                = google_compute_region_target_tcp_proxy.ext-lb-cluster.id
}