# https://cloud.google.com/compute/docs/connect/add-ssh-keys#add_ssh_keys_to_project_metadata
resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = "${var.ssh_user}:${var.public_key} ${var.ssh_user}"
  }
}