# Enable servicenetworking API
resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [google_project_service.servicenetworking]
  create_duration = "60s"
}

# Enable Private Services Access for the VPC
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range-${random_string.tfe.result}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
}

#https://cloud.google.com/sql/docs/mysql/configure-private-services-access
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "postgres_instance" {
  depends_on          = [time_sleep.wait_60_seconds, google_service_networking_connection.private_vpc_connection]
  name                = "${var.region}-${var.instance_name}-${random_string.tfe.result}"
  database_version    = "POSTGRES_13"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-f1-micro" # Machine type, adjust based on your needs
    availability_type = "REGIONAL"

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ENCRYPTED_ONLY"
      private_network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
    }
    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }
}

resource "google_sql_database" "postgres_db" {
  name     = "${var.instance_name}${random_string.tfe.result}"
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "postgres_user" {
  name     = var.db_username
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
}

