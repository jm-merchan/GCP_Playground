# Private Endpoint for internal load balancer
resource "google_compute_address" "internal" {
  name         = "${var.region1}-vault-internal-lb-${random_string.vault.result}"
  region       = var.region1
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.subnet1.id
}

resource "google_compute_address" "internal2" {
  name         = "${var.region1}-vault-internal-lb2-${random_string.vault.result}"
  region       = var.region1
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.subnet1.id
}

# Public Endpoint for public load balancer
resource "google_compute_address" "public" {
  name         = "${var.region1}-vault-public-lb-${random_string.vault.result}"
  region       = var.region1
  address_type = "EXTERNAL"
  # purpose      = "GCE_ENDPOINT"
  # subnetwork   = google_compute_subnetwork.subnet1.id
}

# Health check to load balance against all nodes
resource "google_compute_region_health_check" "lb" {
  name               = "${var.region1}-vault-interal-lb-${var.region1}-${random_string.vault.result}"
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
  name               = "${var.region1}-vault-interal-lb-cluster-${var.region1}-${random_string.vault.result}"
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
  name                  = "${var.region1}-vault-internal-lb-api-${random_string.vault.result}"
  region                = var.region1
  description           = "The backend service of the internal load balancer for Vault"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_name             = "https"
  protocol              = "HTTPS"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

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
  name                  = "${var.region1}-vault-external-lb-api-${random_string.vault.result}"
  region                = var.region1
  description           = "The backend service of the external load balancer for Vault"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "https"
  protocol              = "TCP"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

  backend {
    group           = google_compute_region_instance_group_manager.vault.instance_group
    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}

# External Backend for Vault on port 8201
resource "google_compute_region_backend_service" "lb-ext-cluster" {
  health_checks         = [google_compute_region_health_check.lb_cluster.self_link]
  name                  = "${var.region1}-vault-external-lb-cluster-${random_string.vault.result}"
  region                = var.region1
  description           = "The backend service of the external load balancer for Vault on port 8201"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "cluster" # The port 8201 as defined in the MIG, should be changed to variable
  protocol              = "TCP"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

  backend {
    group           = google_compute_region_instance_group_manager.vault.instance_group
    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}

# External Backend for Vault on port 5696
resource "google_compute_region_backend_service" "lb-ext-kmip" {
  count                 = var.kmip_enable == true ? 1 : 0 # if kmip_enable==true then create, otherwise not
  health_checks         = [google_compute_region_health_check.lb.self_link]
  name                  = "${var.region1}-vault-external-lb-kmip-${random_string.vault.result}"
  region                = var.region1
  description           = "The backend service of the external load balancer for Vault on port 5696"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "kmip"
  protocol              = "TCP"
  timeout_sec           = 10
  session_affinity      = "CLIENT_IP"
  locality_lb_policy    = "RING_HASH"

  backend {
    group           = google_compute_region_instance_group_manager.vault.instance_group
    balancing_mode  = "UTILIZATION"
    description     = "The instance group of the compute deployment for Vault"
    capacity_scaler = 1.0
  }
}


resource "google_compute_region_url_map" "lb" {
  default_service = google_compute_region_backend_service.lb.self_link
  name            = "${var.region1}-vault-internal-lb-${random_string.vault.result}"
  region          = var.region1
  description     = "The URL map of the internal load balancer for Vault"
}

data "google_dns_managed_zone" "env_dns_zone" {
  name = var.dns_zone_name_ext
}
# Create A record for External VIP
resource "google_dns_record_set" "vip" {
  name = "${var.cluster-name}-${var.region1}-${random_string.vault.result}.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas      = [google_compute_address.public.address]
}

# Create A record for Internal VIPs
resource "google_dns_record_set" "vip-int1" {
  name = "vip443-${random_string.vault.result}.${google_dns_managed_zone.private-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private-zone.name
  rrdatas      = [google_compute_address.internal.address]
}

resource "google_dns_record_set" "vip-int2" {
  name = "vip8200-${random_string.vault.result}.${google_dns_managed_zone.private-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private-zone.name
  rrdatas      = [google_compute_address.internal2.address]
}

# Regional SSL Certificate with the content of the Let's Encrypt signed server previously created
resource "google_compute_region_ssl_certificate" "vault_ssl_cert" {
  name   = "${var.region1}-vault-ssl-cert-${random_string.vault.result}"
  region = var.region1
  # private_key = tls_private_key.server.private_key_pem
  private_key = local.vault_key
  # certificate = tls_locally_signed_cert.server.cert_pem # Path to your certificate
  certificate = local.vault_cert
}

# Frontend configuration for internal LB on port 8200
resource "google_compute_region_target_https_proxy" "lb" {
  name             = "${var.region1}-vault-internal-lb-${var.region1}-${random_string.vault.result}"
  region           = var.region1
  ssl_certificates = [google_compute_region_ssl_certificate.vault_ssl_cert.self_link]
  url_map          = google_compute_region_url_map.lb.self_link

  description = "The target HTTPS proxy of the internal load balancer for Vault"
}

# Frontend configuration for external LB on port 8200
resource "google_compute_region_target_tcp_proxy" "ext-lb-api" {
  name            = "${var.region1}-vault-external-lb-api-${var.region1}-${random_string.vault.result}"
  region          = var.region1
  backend_service = google_compute_region_backend_service.lb-ext-api.id
  description     = "The target TCP proxy of the external load balancer for Vault api port"
}

# Frontend configuration for external LB on port 8201
resource "google_compute_region_target_tcp_proxy" "ext-lb-cluster" {
  name            = "${var.region1}-vault-external-lb-cluster-${var.region1}-${random_string.vault.result}"
  region          = var.region1
  backend_service = google_compute_region_backend_service.lb-ext-cluster.id
  description     = "The target TCP proxy of the external load balancer for Vault cluster port"
}

# Frontend configuration for external LB on port 5696
resource "google_compute_region_target_tcp_proxy" "ext-lb-kmip" {
  count           = var.kmip_enable == true ? 1 : 0 # if kmip_enable==true then create, otherwise not
  name            = "${var.region1}-vault-external-lb-kmip-${var.region1}-${random_string.vault.result}"
  region          = var.region1
  backend_service = google_compute_region_backend_service.lb-ext-kmip[count.index].id
  description     = "The target TCP proxy of the external load balancer for Vault kmip port"
}


# Port 443 route for internal load balancer with HTTPS interception
resource "google_compute_forwarding_rule" "lb1" {
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  name                  = "${var.region1}-vault-internal-lb1-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.internal.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 443
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_https_proxy.lb.id
  subnetwork            = google_compute_subnetwork.subnet1.id # same subnet as VIP
}

# Port 8200  route for internal load balancer with HTTPS interception
resource "google_compute_forwarding_rule" "lb2" {
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  name                  = "${var.region1}-vault-internal-lb2-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.internal2.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 8200
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_https_proxy.lb.id
  subnetwork            = google_compute_subnetwork.subnet1.id # same subnet as VIP
}

# Port 8200  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb1" {
  name                  = "${var.region1}-vault-external-lb1-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 8200
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}

# Port 443  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb2" {
  name                  = "${var.region1}-vault-external-lb2-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 443
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-api.id
}

# Port 8201  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb3" {
  name                  = "${var.region1}-vault-external-lb3-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 8201
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-cluster.id
}

# Port 5696  route for external load balancer 
resource "google_compute_forwarding_rule" "ext-lb4" {
  count                 = var.kmip_enable == true ? 1 : 0 # if kmip_enable==true then create, otherwise not
  name                  = "${var.region1}-vault-external-kmip-${random_string.vault.result}"
  region                = var.region1
  ip_address            = google_compute_address.public.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 5696
  network               = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  target                = google_compute_region_target_tcp_proxy.ext-lb-kmip[count.index].id
}