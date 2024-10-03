variable "location" {
  type    = string
  default = "global"
}
variable "region" {
  type    = string
  default = "europe-southwest1"
}

variable "subnet1-region" {
  type        = string
  description = "Subnet to deploy VMs and VIPs"
  default     = "10.0.10.0/24"
}

variable "subnet2-region" {
  type        = string
  description = "Reserverd Range for Private Service Access"
  default     = "10.0.20.0/24"
}

variable "subnet4-region" {
  type        = string
  description = "proxy-only subnet for EXTERNAL LOAD BALANCER"
  default     = "10.0.40.0/24"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "project_id" {
  type        = string
  description = "You GCP project ID"
}


variable "dns_zone_name_ext" {
  type        = string
  description = "Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME"
}

variable "tls_secret_id" {
  type        = string
  description = "Secret id/name given to the google secrets manager secret"
  default     = "boundary-secret-demo"
}


variable "node_count" {
  type    = number
  default = 3
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}



variable "boundary_version" {
  type = string
}


variable "email" {
  type        = string
  description = "Email address to create Certs in ACME request"
}

variable "cluster-name" {
  type        = string
  description = "Prefix to identify the boundary cluster. This name will be used in the public DNS names and certificate"
}

variable "acme_prod" {
  type        = bool
  description = "Whether to use ACME prod url or not"
  default     = false
}

locals {
  acme_prod = var.acme_prod == true ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "boundary_license" {
  description = "BOUNDARY Enterprise License"
  type        = string
  default     = "empty"
  sensitive   = true
}


variable "boundary_enterprise" {
  description = "Whether using BOUNDARY Enterprise or not"
  type        = bool
  default     = true
}


variable "db_username" {
  description = "Postgres username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Postgres user password"
  type        = string
  sensitive   = true
}
