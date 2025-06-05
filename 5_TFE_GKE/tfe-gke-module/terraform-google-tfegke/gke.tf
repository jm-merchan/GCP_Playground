resource "google_container_cluster" "default" {
  name     = var.gke_autopilot_enable ? "${var.region}-autopilot-cluster${random_string.tfe.result}" : "${var.region}-gke-cluster${random_string.tfe.result}"
  location = var.region

  enable_autopilot = var.gke_autopilot_enable
  enable_l4_ilb_subsetting = true

  network    = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  subnetwork = google_compute_subnetwork.subnet1.id

  # Solo para clústeres estándar (no Autopilot)
  dynamic "node_config" {
    for_each = var.gke_autopilot_enable ? [] : [1]
    content {
      machine_type = var.machine_type
    }
  }

  initial_node_count = var.gke_autopilot_enable ? null : var.node_count

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.subnet1.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.subnet1.secondary_ip_range[1].range_name
  }

  deletion_protection = false

  workload_identity_config {
    workload_pool = "${data.google_client_config.default.project}.svc.id.goog"
  }
}


resource "google_service_account" "default" {
  count        = (var.gke_autopilot_enable || var.with_node_pool) ? 0 : 1
  account_id   = "service-account-gke-${random_string.tfe.result}"
  display_name = "Service Account for GKE Node Pool"
}
