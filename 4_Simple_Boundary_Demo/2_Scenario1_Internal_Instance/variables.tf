variable "username" {
  description = "Boundary Username"
  type        = string
}

variable "password" {
  description = "Boundary Password"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "authmethod" {
  description = "Boundary Auth Method ID"
  type        = string
}

variable "public_key" {
  type        = string
  description = "SSH Public key to access instances"
}


variable "scenario1_target_alias" {
  type        = string
  description = "Alias for first target"
  default     = "scenario1.gcp.boundary.demo"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "GCP VM Machine type"
}

variable "allowed_networks" {
  type        = string
  description = "Define networks for inbound traffic access"
}

variable "ssh_user" {
  type    = string
  default = "admin"

}

variable "private_key" {
  type      = string
  sensitive = true
}

variable "worker_tag" {
  type    = string
  default = "worker1"

}