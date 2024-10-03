variable "location" {
  type = string
}
variable "region" {
  type = string
}

variable "project_id" {
  type        = string
  description = "You GCP project ID"
}

variable "dns_zone_name_ext" {
  type        = string
  description = "Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME"
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


variable "vault_version" {
  description = "Vault version expressed as X{n}.X{1,n}.X{1,n}, for example 1.16.3"
  type        = string
}

variable "vault_license" {
  description = "Vault Enterprise License as string"
  type        = string
  default     = "empty"
  sensitive   = true
}

variable "vault_enterprise" {
  description = "Whether using Vault Enterprise or not"
  type        = bool
}

locals {
  vault_version = var.vault_enterprise == false ? var.vault_version : "${var.vault_version}-ent"
}

variable "subnet-proxyOnly" {
  type    = string
  default = "10.250.250.0/24"
}