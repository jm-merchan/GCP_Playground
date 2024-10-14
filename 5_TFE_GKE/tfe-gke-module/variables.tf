variable "project_id" {
  type = string
}

variable "acme_prod" {
  type        = bool
  description = "Whether to use ACME prod url or staging one. The staging certificate will not be trusted by default"
  default     = false
}

locals {
  acme_prod = var.acme_prod == true ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "email" {
  type        = string
  description = "Email address to create Certs in ACME request"
}

variable "dns_zone_name_ext" {
  type        = string
  description = "Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME"
}


variable "vault_version" {
  description = "Vault version expressed as X{n}.X{1,n}.X{1,n}, for example 1.16.3"
  type        = string
}

variable "region" {
  type = string
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
  default     = true
}

locals {
  vault_version = var.vault_enterprise == false ? var.vault_version : "${var.vault_version}-ent"
}