# Create subnets in a given region
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.region}-target1"
  ip_cidr_range = "10.253.253.0/24"
  region        = var.region
  network       = data.terraform_remote_state.local_backend.outputs.vpc_id
}

# Allow SSH to target1
resource "google_compute_firewall" "allow_SSH_target1" {
  name    = "allow-ssh-target-1"
  network = data.terraform_remote_state.local_backend.outputs.vpc_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [
    var.allowed_networks,
    "35.235.240.0/20",
  ] # Allow from defined CIDR range
  target_service_accounts = [google_service_account.main.email, google_service_account.worker.email]
  direction               = "INGRESS"
}


# Allow Inbound traffic to worker
resource "google_compute_firewall" "allow_9202_worker1" {
  name    = "allow-9202-worker-1"
  network = data.terraform_remote_state.local_backend.outputs.vpc_id
  allow {
    protocol = "tcp"
    ports    = ["9202"]
  }
  source_ranges = [
    var.allowed_networks,
  ] # Allow from defined CIDR range
  target_service_accounts = [google_service_account.worker.email]
  direction               = "INGRESS"
}

