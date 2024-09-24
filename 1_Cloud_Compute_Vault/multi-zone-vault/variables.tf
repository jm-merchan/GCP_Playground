variable "location" {
  type    = string
  default = "global"
}
variable "region1" {
  type    = string
  default = "europe-west1"
}

variable "subnet1-region1" {
  type        = string
  description = "Subnet to deploy VMs and VIPs"
  default     = "10.0.1.0/24"
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
  description = "proxy-only subnet for EXTERNAL LOAD BALANCER"
  default     = "10.0.4.0/24"
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
  default     = "vault-secret-demo"
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
  type = string
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
  default = "vmdemo"
}

variable "dns_zone_name_int" {
  type    = string
  default = "lab.int."
}

variable "email" {
  type        = string
  description = "Email address to create Certs in ACME request"
}

variable "cluster-name" {
  type        = string
  description = "Prefix to identify the vault cluster. This name will be used in the public DNS names and certificate"
}

variable "acme_prod" {
  type        = bool
  description = "Whether to use ACME prod url or not"
  default     = false
}

locals {
  acme_prod = var.acme_prod == true ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "vault_license" {
  description = "Vault Enterprise License"
  type        = string
  default     = "empty"
  sensitive   = true
}

variable "allowed_networks" {
  description = "CIDR range allowed to connect to Vault from Internet"
  type        = string
}

variable "networking_healthcheck_ips" {
  description = "GCP Health Check IPs: https://cloud.google.com/load-balancing/docs/health-check-concepts?hl=es-419"
  type        = list(any)
  default     = ["35.191.0.0/16", "130.211.0.0/22"]
}

variable "vault_enterprise" {
  description = "Whether using Vault Enterprise or not"
  type        = bool
  default     = true
}

variable "kmip_enable" {
  description = "Enable kmip loadbalancer. Requires Vault Enterprise"
  type        = bool
  default     = false
}

variable "vault_log_path" {
  description = "Path to store Vault logs. Logrotate and Ops Agent are configured to operate with logs in this path"
  type        = string
  default     = "/var/log/vault.log"
}

variable "gce_ssh_user" {
  description = "SSH username"
  type = string
  
}

variable "gce_ssh_pub_key_file" {
  description = "SSH Public key to access to Vault"
  type = string
  
}