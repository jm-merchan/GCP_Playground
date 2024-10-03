
data "google_compute_network" "network" {
  count = var.create_vpc == false ? 1 : 0
  name  = var.vpc_name
  project = var.project_id
}

locals {
  vpc_reference = var.create_vpc == false ?  data.google_compute_network.network[0].id : null
}