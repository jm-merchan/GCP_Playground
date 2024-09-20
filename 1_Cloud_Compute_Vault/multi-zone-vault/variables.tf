variable "location" {
  type    = string
  default = "global"
}
variable "region1" {
  type    = string
  default = "europe-west1"
}

variable "subnet1-region1" {
  type    = string
  default = "10.0.1.0/24"
}
variable "subnet2-region1" {
  type    = string
  default = "10.0.2.0/24"
}
variable "subnet3-region1" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subnet4-region1" {
  type        = string
  description = "proxy-only"
  default     = "10.0.4.0/24"
}

variable "vpc_name" {
  type    = string
  default = "global-vpc"
}

variable "project_id" {
  type    = string
  default = "hc-481920a3f7e54d39b33d0454ff9"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "dns_zone_name_ext" {
  type    = string
  default = "doormat-useremail"

}

variable "tls_secret_id" {
  type        = string
  description = "Secret id/name given to the google secrets manager secret"
  default     = "vault"
}

variable "storage_location" {
  type        = string
  description = "The location of the storage bucket for the Vault license."
  default     = "EU"
}

variable "vault_license_filepath" {
  type        = string
  description = "Filepath to location of Vault license file"
  default     = "/Users/jose/Demo/Vault_ADP/ADP_PlayGround/vault.hclic"
}

variable "vault_license_name" {
  type        = string
  description = "Filename for Vault license file"
  default     = "vault.hclic"
}

variable "shared_san" {
  type        = string
  description = "This is a shared server name that the certs for all Vault nodes contain. This is the same value you will supply as input to the Vault installation module for the leader_tls_servername variable"
  default     = "vault.server.com"
}

variable "node_count" {
  type    = number
  default = 5
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "disk_size" {
  type    = number
  default = 30
}

variable "disk_type" {
  type    = string
  default = "pd-standard"

}

variable "vault_version" {
  type    = string
  default = "1.17.5"

}

variable "vault_lb_health_check" {
  type    = string
  default = "/v1/sys/health?activecode=200&standbycode=200&sealedcode=200&uninitcode=200"

}

variable "vault_lb_cluster_health_check" {
  type    = string
  default = "/v1/sys/health?activecode=200&standbycode=500&performancestandbycode=500"
}

variable "resource_name_prefix" {
  type    = string
  default = "vm"
}

variable "dns_zone_name_int" {
  type    = string
  default = "lab.int."

}