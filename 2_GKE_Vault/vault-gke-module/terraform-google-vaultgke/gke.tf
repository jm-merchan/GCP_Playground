resource "google_container_cluster" "default" {
  # Add reference to autopilot in name if autopilot cluster
  name = var.gke_autopilot_enable == false ? "${var.region}-gke-cluster${random_string.vault.result}" : "${var.region}-autopilot-cluster${random_string.vault.result}"

  location                 = var.region
  enable_autopilot         = var.gke_autopilot_enable
  enable_l4_ilb_subsetting = true

  network            = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  subnetwork         = google_compute_subnetwork.subnet1.id 
  initial_node_count = 1

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.subnet1.secondary_ip_range[0].range_name 
    cluster_secondary_range_name  = google_compute_subnetwork.subnet1.secondary_ip_range[1].range_name 
  }

  # Set `deletion_protection` to `true` will ensure that one cannot
  # accidentally delete this instance by use of Terraform.
  deletion_protection = false

  # IMPORTANT required to enable workload identity
  workload_identity_config {
    workload_pool = "${data.google_client_config.default.project}.svc.id.goog"
  }
}


resource "google_service_account" "default" {
  count        = (var.gke_autopilot_enable || var.with_node_pool) ? 0 : 1
  account_id   = "service-account-gke-${random_string.vault.result}"
  display_name = "Service Account for GKE Node Pool"
}


# Uncomment to enable node pool
resource "google_container_node_pool" "primary_preemptible_nodes" {
  count      = (var.gke_autopilot_enable || var.with_node_pool) ? 0 : 1
  name       = "${var.region}-node-pool-${random_string.vault.result}"
  location   = var.region
  cluster    = google_container_cluster.default.name
  node_count = 3


  node_config {
    preemptible  = true
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default[0].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}