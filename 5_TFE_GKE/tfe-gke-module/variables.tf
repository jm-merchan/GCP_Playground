variable "dns_zone_name_ext" {
  type        = string
  description = "Nombre de la zona DNS externa"
}

variable "acme_prod" {
  type        = bool
  description = "Whether to use ACME prod url or staging one. The staging certificate will not be trusted by default"
  default     = false
}

locals {
  acme_prod = var.acme_prod == true ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "project_id" {
  type        = string
  description = "ID del proyecto de GCP"
}

variable "vpc_name" {
  type        = string
  description = "Nombre de la VPC"
}

variable "region" {
  type        = string
  description = "Región donde desplegar recursos"
  default     = "europe-west1"
}

variable "location" {
  type        = string
  description = "Ubicación (location) para recursos globales"
  default     = "global"
}

variable "email" {
  type        = string
  description = "Correo electrónico para solicitudes ACME"
}

variable "instance_name" {
  type        = string
  description = "Nombre de la instancia de Postgres"
  default     = "postgres-instance"
}

variable "tfe_license" {
  type        = string
  description = "Licencia de TFE"
  sensitive   = true
  default     = ""
}

variable "node_count" {
  type        = number
  description = "Número de nodos del clúster GKE"
  default     = 3
}

variable "db_username" {
  type        = string
  description = "Usuario de la base de datos Postgres"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Contraseña del usuario de la base de datos Postgres"
  sensitive   = true
}

variable "create_network" {
  type        = bool
  description = "Crear red nueva o usar existente"
  default     = true
}

variable "expose" {
  type        = string
  description = "Exponer el balanceador de carga como 'Internal' o 'External'"
  default     = "External"
  validation {
    condition     = contains(["Internal", "External"], var.expose)
    error_message = "El valor debe ser 'Internal' o 'External'"
  }
}

variable "tfe_version" {
  type        = string
  description = "Versión de TFE a desplegar"
  default     = "v202409-3"
}