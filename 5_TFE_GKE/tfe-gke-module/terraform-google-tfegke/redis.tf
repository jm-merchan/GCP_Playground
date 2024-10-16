# https://cloud.google.com/memorystore/docs/redis/create-instance-terraform

# Enable MemoryStore API
resource "google_project_service" "redis" {
  project = var.project_id
  service = "redis.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_redis_instance" "my_memorystore_redis_tfe" {
  depends_on         = [google_project_service.redis, time_sleep.wait_60_seconds]
  name               = "tfe-${random_string.tfe.result}"
  tier               = "BASIC"
  memory_size_gb     = 2
  region             = var.region
  redis_version      = "REDIS_6_X"
  authorized_network = var.create_vpc == true ? google_compute_network.global_vpc[0].id : local.vpc_reference
  display_name       = "TFE Redis"

}