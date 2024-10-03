# Public Endpoint for public load balancer
resource "google_compute_address" "public" {
  name         = "${var.region}-boundary-public-lb-${random_string.boundary.result}"
  region       = var.region
  address_type = "EXTERNAL"
}

# Health check to load balance against all nodes
resource "google_compute_region_health_check" "lb" {
  name               = "${var.region}-boundary-${random_string.boundary.result}"
  region             = var.region
  check_interval_sec = 30
  description        = "The health check of the internal load balancer for BOUNDARY"
  timeout_sec        = 4

  https_health_check {
    port         = 9203
    request_path = var.boundary_lb_health_check
  }
}


# External Backend for BOUNDARY on port 9200
resource "google_compute_region_backend_service" "lb-ext-api" {
  health_checks         = [google_compute_region_health_check.lb.self_link]
  name                  = "${var.region}-boundary-api-${random_string.boundary.result}"
  region                = var.region
  description           = "The backend service of the external load balancer for BOUNDARY"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "api"
  protocol              = "TCP"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

  backend {
    group           = google_compute_region_instance_group_manager.boundary.instance_group
    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for BOUNDARY"
    capacity_scaler = 1.0
  }
}

# External Backend for BOUNDARY on port 9201
resource "google_compute_region_backend_service" "lb-ext-cluster" {
  health_checks         = [google_compute_region_health_check.lb.self_link]
  name                  = "${var.region}-boundary-cluster-${random_string.boundary.result}"
  region                = var.region
  description           = "The backend service of the external load balancer for BOUNDARY on cluster port"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "cluster"
  protocol              = "TCP"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

  backend {
    group           = google_compute_region_instance_group_manager.boundary.instance_group
    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for BOUNDARY"
    capacity_scaler = 1.0
  }
}

data "google_dns_managed_zone" "env_dns_zone" {
  name = var.dns_zone_name_ext
}
# Create A record for External VIP
resource "google_dns_record_set" "vip" {
  name = "${var.cluster-name}-${var.region}-${random_string.boundary.result}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [google_compute_address.public.address]
}


# Regional SSL Certificate with the content of the Let's Encrypt signed server previously created
resource "google_compute_region_ssl_certificate" "boundary_ssl_cert" {
  name   = "${var.region}-boundary-ssl-cert-${random_string.boundary.result}"
  region = var.region
  # private_key = tls_private_key.server.private_key_pem
  private_key = local.boundary_key
  # certificate = tls_locally_signed_cert.server.cert_pem # Path to your certificate
  certificate = local.boundary_cert
}

# Frontend configuration for external LB on port 9200
resource "google_compute_region_target_tcp_proxy" "ext-lb-api" {
  name            = "${var.region}-boundary-lb-api-${random_string.boundary.result}"
  region          = var.region
  backend_service = google_compute_region_backend_service.lb-ext-api.id
  description     = "The target TCP proxy of the external load balancer for BOUNDARY api port"
}

# Frontend configuration for external LB on port 9201
resource "google_compute_region_target_tcp_proxy" "ext-lb-cluster" {
  name            = "${var.region}-boundary-lb-cluster-${random_string.boundary.result}"
  region          = var.region
  backend_service = google_compute_region_backend_service.lb-ext-cluster.id
  description     = "The target TCP proxy of the external load balancer for BOUNDARY cluster port"
}

# Port 9200  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb1" {
  name                  = "${var.region}-boundary-api-${random_string.boundary.result}"
  region                = var.region
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 9200
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}

# Port 9201  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb2" {
  name                  = "${var.region}-boundary-cluster-${random_string.boundary.result}"
  region                = var.region
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 9201
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-cluster.id
}

# Port 443  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb3" {
  name                  = "${var.region}-boundary-api443-${random_string.boundary.result}"
  region                = var.region
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 443
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}