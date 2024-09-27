In this first repo we are going to deploy the archetypical Vault Deployment as described in the [Raft Reference Architecture](https://developer.hashicorp.com/vault/tutorials/day-one-raft/raft-reference-architecture). There are many good examples of how to do this, modules included. One that is particularly nice and that I have used as reference is this one: [terraform-gcp-vault-starter](https://github.com/hashicorp/terraform-gcp-vault-starter). The module works as template or skeleton module that calls another set of specialized modules to create a number of resources: NLB, KMS, Secrets, Storage,... To simplify the work I have removed the nested structure to work with a single module.

More prescriptive installation steps can be found within the HVD reference modules: [https://registry.terraform.io/modules/hashicorp/vault-enterprise-hvd/google/latest](https://registry.terraform.io/modules/hashicorp/vault-enterprise-hvd/google/latest)

The reference module created a number of Vault instances within a single-zone managed group, where Vault API is just accesible from within the VPC (this is the recomended approach). I have extended this structure to deploy not just an internal load balancer but also external load balancers. These load balancers provide access to the API (in a load-balancing function) and the cluster port (just pointing to the leader node of the raft cluster). **Optionally**, you can enable an extra load balancer to provide access to the KMIP default port. Allowing access to the cluster port is important as it allows for bulding replication relationships with secondary servers, whether those are used for Disaster Recovery (DR) or Performance Replicaton (PR) proposes

There are other changes are listed below:

* Let's encrypt generated certificate for Vault (with option to use production or staging CA).
* Inclusiong of Google Ops Agent in the VM to capture both audit logs and Promethus metrics. Part of the agent metric scrapping settings must be set "manually" after VM instances have been provisioned, as the Ops Agent required a Vault token to access a certain path within the API.
* Inclusion of log-rotate to rotate Vault audit logs.
* Steps to enable automatic snapshots
* Cluster Port Layer-4 load-balancer
* KMIP Layer-4 load-balancer
* Steps to initialize Vault and save the root token and recovery keys as GCP Secret.

There is an issue with the usage of MIG and an stateful app as Vault. MIG are designed for stateless apps and so things like getting the IPs of the managed instance required of a set of data sources, as described in this [issue](https://github.com/hashicorp/terraform-provider-google/issues/1246). We can tacke it by having separate Terraform code that does the initialization as a second apply. Othere posibilitty could be to place the Prometheus scrappers outside of the Vault host VMs. However for simplicity everything is placed inside. The side effect of this is that if a Vault VM is recreated, the Prometheus configuration of the Ops Agent will have to be re-applied, since the script template does not uses a proper Vault token.

## Prerequisites

* Public DNS Zone precreated (allow some time for propagation)
* Cloud Secret API enabled
* Cloud KMS API enabled


## Requirements

| Name                                                              | Version |
| ----------------------------------------------------------------- | ------- |
| `<a name="requirement_acme"></a>` [acme](#requirement\_acme)       | 2.26.0  |
| `<a name="requirement_google"></a>` [google](#requirement\_google) | 6.3.0   |
| `<a name="requirement_null"></a>` [null](#requirement\_null)       | 3.2.3   |
| `<a name="requirement_random"></a>` [random](#requirement\_random) | 3.6.3   |
| `<a name="requirement_time"></a>` [time](#requirement\_time)       | 0.12.1  |
| `<a name="requirement_tls"></a>` [tls](#requirement\_tls)          | 4.0.6   |

## Providers

| Name                                                        | Version |
| ----------------------------------------------------------- | ------- |
| `<a name="provider_acme"></a>` [acme](#provider\_acme)       | 2.26.0  |
| `<a name="provider_google"></a>` [google](#provider\_google) | 6.3.0   |
| `<a name="provider_random"></a>` [random](#provider\_random) | 3.6.3   |
| `<a name="provider_time"></a>` [time](#provider\_time)       | 0.12.1  |
| `<a name="provider_tls"></a>` [tls](#provider\_tls)          | 4.0.6   |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                         | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [acme_certificate.certificate](https://registry.terraform.io/providers/vancluever/acme/2.26.0/docs/resources/certificate)                                                       | resource    |
| [acme_registration.registration](https://registry.terraform.io/providers/vancluever/acme/2.26.0/docs/resources/registration)                                                    | resource    |
| [google_compute_address.internal](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_address)                                                | resource    |
| [google_compute_address.internal2](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_address)                                               | resource    |
| [google_compute_address.public](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_address)                                                  | resource    |
| [google_compute_firewall.allow_internal](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                                        | resource    |
| [google_compute_firewall.allow_vault_all_external](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                              | resource    |
| [google_compute_firewall.allow_vault_outbound](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                                  | resource    |
| [google_compute_firewall.lb_healthchecks](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                                       | resource    |
| [google_compute_firewall.lb_proxy](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                                              | resource    |
| [google_compute_firewall.ssh](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_firewall)                                                   | resource    |
| [google_compute_forwarding_rule.ext-lb1](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                 | resource    |
| [google_compute_forwarding_rule.ext-lb2](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                 | resource    |
| [google_compute_forwarding_rule.ext-lb3](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                 | resource    |
| [google_compute_forwarding_rule.ext-lb4](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                 | resource    |
| [google_compute_forwarding_rule.lb1](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                     | resource    |
| [google_compute_forwarding_rule.lb2](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_forwarding_rule)                                     | resource    |
| [google_compute_instance_template.vault](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_instance_template)                               | resource    |
| [google_compute_network.global_vpc](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_network)                                              | resource    |
| [google_compute_region_backend_service.lb](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_backend_service)                        | resource    |
| [google_compute_region_backend_service.lb-ext-api](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_backend_service)                | resource    |
| [google_compute_region_backend_service.lb-ext-cluster](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_backend_service)            | resource    |
| [google_compute_region_backend_service.lb-ext-kmip](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_backend_service)               | resource    |
| [google_compute_region_health_check.lb](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_health_check)                              | resource    |
| [google_compute_region_health_check.lb_cluster](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_health_check)                      | resource    |
| [google_compute_region_instance_group_manager.vault](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_instance_group_manager)       | resource    |
| [google_compute_region_ssl_certificate.main](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_ssl_certificate)                      | resource    |
| [google_compute_region_ssl_certificate.vault_ssl_cert](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_ssl_certificate)            | resource    |
| [google_compute_region_target_https_proxy.lb](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_target_https_proxy)                  | resource    |
| [google_compute_region_target_tcp_proxy.ext-lb-api](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_target_tcp_proxy)              | resource    |
| [google_compute_region_target_tcp_proxy.ext-lb-cluster](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_target_tcp_proxy)          | resource    |
| [google_compute_region_target_tcp_proxy.ext-lb-kmip](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_target_tcp_proxy)             | resource    |
| [google_compute_region_url_map.lb](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_region_url_map)                                        | resource    |
| [google_compute_router.custom_router](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_router)                                             | resource    |
| [google_compute_router_nat.custom_nat](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_router_nat)                                        | resource    |
| [google_compute_subnetwork.proxy_only_subnet](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_subnetwork)                                 | resource    |
| [google_compute_subnetwork.subnet1](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_subnetwork)                                           | resource    |
| [google_compute_subnetwork.subnet2](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_subnetwork)                                           | resource    |
| [google_compute_subnetwork.subnet3](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/compute_subnetwork)                                           | resource    |
| [google_dns_managed_zone.private-zone](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/dns_managed_zone)                                          | resource    |
| [google_dns_record_set.vip](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/dns_record_set)                                                       | resource    |
| [google_dns_record_set.vip-int1](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/dns_record_set)                                                  | resource    |
| [google_dns_record_set.vip-int2](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/dns_record_set)                                                  | resource    |
| [google_kms_crypto_key.vault_key](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/kms_crypto_key)                                                 | resource    |
| [google_kms_key_ring.key_ring](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/kms_key_ring)                                                      | resource    |
| [google_kms_key_ring_iam_binding.vault_iam_kms_binding](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/kms_key_ring_iam_binding)                 | resource    |
| [google_project_iam_custom_role.autojoin_role](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_custom_role)                           | resource    |
| [google_project_iam_custom_role.keys](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_custom_role)                                    | resource    |
| [google_project_iam_custom_role.kms_role](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_custom_role)                                | resource    |
| [google_project_iam_custom_role.secret_creator](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_custom_role)                          | resource    |
| [google_project_iam_member.logging](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_member)                                           | resource    |
| [google_project_iam_member.vault_auto_join](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_member)                                   | resource    |
| [google_project_iam_member.vault_keys](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_member)                                        | resource    |
| [google_project_iam_member.vault_log](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_member)                                         | resource    |
| [google_project_iam_member.vault_secret](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_iam_member)                                      | resource    |
| [google_project_service.cloudkms](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/project_service)                                                | resource    |
| [google_secret_manager_secret.secret_tls](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/secret_manager_secret)                                  | resource    |
| [google_secret_manager_secret_iam_member.secret_manager_member](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/secret_manager_secret_iam_member) | resource    |
| [google_secret_manager_secret_version.secret_version_basic](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/secret_manager_secret_version)        | resource    |
| [google_service_account.main](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/service_account)                                                    | resource    |
| [google_storage_bucket.vault_license_bucket](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/storage_bucket)                                      | resource    |
| [google_storage_bucket_iam_member.member_object](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/resources/storage_bucket_iam_member)                       | resource    |
| [random_string.vault](https://registry.terraform.io/providers/hashicorp/random/3.6.3/docs/resources/string)                                                                     | resource    |
| [time_sleep.wait_20_seconds](https://registry.terraform.io/providers/hashicorp/time/0.12.1/docs/resources/sleep)                                                                | resource    |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/4.0.6/docs/resources/private_key)                                                                    | resource    |
| [tls_private_key.private_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.6/docs/resources/private_key)                                                           | resource    |
| [google_compute_image.debian](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/data-sources/compute_image)                                                   | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/data-sources/compute_zones)                                                | data source |
| [google_dns_managed_zone.env_dns_zone](https://registry.terraform.io/providers/hashicorp/google/6.3.0/docs/data-sources/dns_managed_zone)                                       | data source |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                                                        | Type          | Default                                                                                            | Required |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | -------------------------------------------------------------------------------------------------- | :------: |
| `<a name="input_allowed_networks"></a>` [allowed\_networks](#input\_allowed\_networks)                                 | CIDR range allowed to connect to Vault from Internet                                                                                                                                               | `string`    | `"0.0.0.0/0"`                                                                                    |    no    |
| `<a name="input_cluster-name"></a>` [cluster-name](#input\_cluster-name)                                               | Prefix to identify the vault cluster. This name will be used in the public DNS names and certificate                                                                                               | `string`    | n/a                                                                                                |   yes   |
| `<a name="input_disk_size"></a>` [disk\_size](#input\_disk\_size)                                                      | n/a                                                                                                                                                                                                | `number`    | `30`                                                                                             |    no    |
| `<a name="input_disk_type"></a>` [disk\_type](#input\_disk\_type)                                                      | n/a                                                                                                                                                                                                | `string`    | `"pd-standard"`                                                                                  |    no    |
| `<a name="input_dns_zone_name_ext"></a>` [dns\_zone\_name\_ext](#input\_dns\_zone\_name\_ext)                          | Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME                                                                     | `string`    | n/a                                                                                                |   yes   |
| `<a name="input_dns_zone_name_int"></a>` [dns\_zone\_name\_int](#input\_dns\_zone\_name\_int)                          | n/a                                                                                                                                                                                                | `string`    | `"lab.int."`                                                                                     |    no    |
| `<a name="input_email"></a>` [email](#input\_email)                                                                    | Email address to create Certs in ACME request                                                                                                                                                      | `string`    | n/a                                                                                                |   yes   |
| `<a name="input_kmip_enable"></a>` [kmip\_enable](#input\_kmip\_enable)                                                | Enable kmip loadbalancer. Requires Vault Enterprise                                                                                                                                                | `bool`      | `false`                                                                                          |    no    |
| `<a name="input_location"></a>` [location](#input\_location)                                                           | n/a                                                                                                                                                                                                | `string`    | `"global"`                                                                                       |    no    |
| `<a name="input_machine_type"></a>` [machine\_type](#input\_machine\_type)                                             | n/a                                                                                                                                                                                                | `string`    | `"e2-medium"`                                                                                    |    no    |
| `<a name="input_networking_healthcheck_ips"></a>` [networking\_healthcheck\_ips](#input\_networking\_healthcheck\_ips) | GCP Health Check IPs: https://cloud.google.com/load-balancing/docs/health-check-concepts?hl=es-419                                                                                                 | `list(any)` | `<pre>`[``  "35.191.0.0/16",``  "130.211.0.0/22"``]`</pre>`                                    |    no    |
| [node\_count](#input\_node\_count)                                                                                       | n/a                                                                                                                                                                                                | `number`    | `5`                                                                                              |    no    |
| [project\_id](#input\_project\_id)                                                                                       | You GCP project ID                                                                                                                                                                                 | `string`    | n/a                                                                                                |   yes   |
| [region1](#input\_region1)                                                                                               | n/a                                                                                                                                                                                                | `string`    | `"europe-west1"`                                                                                 |    no    |
| [resource\_name\_prefix](#input\_resource\_name\_prefix)                                                                 | n/a                                                                                                                                                                                                | `string`    | `"vmdemo"`                                                                                       |    no    |
| [shared\_san](#input\_shared\_san)                                                                                       | This is a shared server name that the certs for all Vault nodes contain. This is the same value you will supply as input to the Vault installation module for the leader\_tls\_servername variable | `string`    | `"vault.server.com"`                                                                             |    no    |
| [storage\_location](#input\_storage\_location)                                                                           | The Geo to store the snapshots                                                                                                                                                                     | `string`    | `"EU"`                                                                                           |    no    |
| [subnet1-region1](#input\_subnet1-region1)                                                                               | Subnet to deploy VMs and VIPs                                                                                                                                                                      | `string`    | `"10.0.1.0/24"`                                                                                  |    no    |
| [subnet2-region1](#input\_subnet2-region1)                                                                               | n/a                                                                                                                                                                                                | `string`    | `"10.0.2.0/24"`                                                                                  |    no    |
| [subnet3-region1](#input\_subnet3-region1)                                                                               | n/a                                                                                                                                                                                                | `string`    | `"10.0.3.0/24"`                                                                                  |    no    |
| [subnet4-region1](#input\_subnet4-region1)                                                                               | proxy-only subnet for EXTERNAL LOAD BALANCER                                                                                                                                                       | `string`    | `"10.0.4.0/24"`                                                                                  |    no    |
| [tls\_secret\_id](#input\_tls\_secret\_id)                                                                               | Secret id/name given to the google secrets manager secret                                                                                                                                          | `string`    | `"vault-and-lb-certificate"`                                                                     |    no    |
| [vault\_enterprise](#input\_vault\_enterprise)                                                                           | Whether using Vault Enterprise or not                                                                                                                                                              | `bool`      | `true`                                                                                           |    no    |
| [vault\_lb\_cluster\_health\_check](#input\_vault\_lb\_cluster\_health\_check)                                           | n/a                                                                                                                                                                                                | `string`    | `"/v1/sys/health?activecode=200&standbycode=500&performancestandbycode=500"`                     |    no    |
| [vault\_lb\_health\_check](#input\_vault\_lb\_health\_check)                                                             | n/a                                                                                                                                                                                                | `string`    | `"/v1/sys/health?activecode=200&standbycode=200&performancestandbycode=200&drsecondarycode=200"` |    no    |
| [vault\_license](#input\_vault\_license)                                                                                 | Vault Enterprise License                                                                                                                                                                           | `string`    | `"empty"`                                                                                        |    no    |
| [vault\_log\_path](#input\_vault\_log\_path)                                                                             | Path to store Vault logs. Logrotate and Ops Agent are configured to operate with logs in this path                                                                                                 | `string`    | `"/var/log/vault.log"`                                                                           |    no    |
| [vault\_version](#input\_vault\_version)                                                                                 | n/a                                                                                                                                                                                                | `string`    | n/a                                                                                                |   yes   |
| [vpc\_name](#input\_vpc\_name)                                                                                           | VPC Name                                                                                                                                                                                           | `string`    | n/a                                                                                                |   yes   |

## Outputs

| Name                                                 | Description |
| ---------------------------------------------------- | ----------- |
| [fqdn\_443](#output\_fqdn\_443)                         | n/a         |
| [fqdn\_8200](#output\_fqdn\_8200)                       | n/a         |
| [gcs\_bucket\_snapshot](#output\_gcs\_bucket\_snapshot) | n/a         |
| [init\_auto\_snapshot](#output\_init\_auto\_snapshot)   | n/a         |
| [init\_remote](#output\_init\_remote)                   | n/a         |
| [init\_script\_node1](#output\_init\_script\_node1)     | n/a         |
| [init\_script\_node2-X](#output\_init\_script\_node2-X) | n/a         |
| [pri\_fqdn\_443](#output\_pri\_fqdn\_443)               | n/a         |
| [pri\_fqdn\_8200](#output\_pri\_fqdn\_8200)             | n/a         |
| [sa-name](#output\_sa-name)                             | n/a         |
