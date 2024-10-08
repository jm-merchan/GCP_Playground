variable "create_network" {
  type        = bool
  description = "Whether to use an existing VPC and Subnets or create them"
  default     = true
}
variable "vpc_name" {
  type        = string
  description = "Name of VPC to be created. The actual number will be randomize with a random suffix"
}

variable "vpc_reference" {
  type        = string
  description = "id or self_link of vpc that will be used to host the EKS cluster."
  default     = ""
}

variable "project_id" {
  type        = string
  description = "You GCP project ID"
}

variable "dns_zone_name_ext" {
  type        = string
  description = "Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME"
}

variable "location" {
  type    = string
  default = "global"
}
variable "region" {
  type    = string
  default = "europe-west1"
}

variable "subnet1-region" {
  type        = string
  description = "Subnet to deploy VMs and VIPs"
  default     = "10.0.1.0/24"
}

variable "subnet_reference" {
  type        = string
  description = "id or self_link of subnet that will be used to host the EKS cluster"
  default     = ""
}


variable "subnet2-region" {
  type        = string
  description = "proxy-only subnet for EXTERNAL LOAD BALANCER"
  default     = "10.0.2.0/24"
}

variable "gke_autopilot_enable" {
  description = "Whether to enable or not GKE Autopilot"
  default     = false
  type        = bool
}

variable "machine_type" {
  description = "Machine type"
  type    = string
  default = "e2-medium"
}

variable "vault_version" {
  description = "Vault version expressed as X{n}.X{1,n}.X{1,n}, for example 1.16.3"
  type = string
}

variable "cluster-name" {
  type        = string
  description = "Prefix to identify the vault cluster. This name will be used in the public DNS names and certificate"
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

variable "vault_license" {
  description = "Vault Enterprise License as string"
  type        = string
  default     = "empty"
  sensitive   = true
}

locals {
  vault_version = var.vault_enterprise == false ? var.vault_version : "${var.vault_version}-ent"
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

variable "k8s_namespace" {
  type        = string
  description = "K8S namespace where to install Vault"
  default     = "vault"
}

variable "vault_helm_release" {
  type        = string
  description = "Helm release for Vault"
  default     = "0.28.1"
}

variable "node_count" {
  type    = number
  description = "Number of Vault instances. Typically 3 or 5"
  default = 3
}

variable "storage_location" {
  description = "The Geo to store the snapshots"
  type        = string
  default     = "EU"

}

variable "with_node_pool" {
  description = "Whether to use node pools. It does not apply when autopilot is used"
  type        = bool
  default     = false
}

variable "create_vpc" {
  description = "Whether to create a VPC"
  default     = true
  type        = bool
}

variable "expose" {
  description = "Whether to make Vault LB Internal or External"
  type = string
  validation {
    condition     = contains(["Internal", "External"], var.expose)
    error_message = "The expose variable must be one of 'Internal' or 'External'"
  }
  
}