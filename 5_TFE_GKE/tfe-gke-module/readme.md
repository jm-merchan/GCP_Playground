## Requirements

| Name                                                              | Version |
| ----------------------------------------------------------------- | ------- |
| `<a name="requirement_acme"></a>` [acme](#requirement\_acme)       | 2.26.0  |
| `<a name="requirement_google"></a>` [google](#requirement\_google) | 6.3.0   |

## Providers

No providers.

## Modules

| Name                                                    | Source                      | Version |
| ------------------------------------------------------- | --------------------------- | ------- |
| `<a name="module_vault1"></a>` [vault1](#module\_vault1) | ./terraform-google-vaultgke | n/a     |
| `<a name="module_vault2"></a>` [vault2](#module\_vault2) | ./terraform-google-vaultgke | n/a     |

## Resources

No resources.

## Inputs

| Name                                                                                         | Description                                                                                                                    | Type       | Default     | Required |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------- | ----------- | :------: |
| `<a name="input_acme_prod"></a>` [acme\_prod](#input\_acme\_prod)                             | Whether to use ACME prod url or staging one. The staging certificate will not be trusted by default                            | `bool`   | `false`   |    no    |
| `<a name="input_dns_zone_name_ext"></a>` [dns\_zone\_name\_ext](#input\_dns\_zone\_name\_ext) | Name of the External DNS Zone that must be precreated in your project. This will help in creating your public Certs using ACME | `string` | n/a         |   yes   |
| `<a name="input_email"></a>` [email](#input\_email)                                           | Email address to create Certs in ACME request                                                                                  | `string` | n/a         |   yes   |
| `<a name="input_project_id"></a>` [project\_id](#input\_project\_id)                          | n/a                                                                                                                            | `string` | n/a         |   yes   |
| `<a name="input_region"></a>` [region](#input\_region)                                        | n/a                                                                                                                            | `string` | n/a         |   yes   |
| `<a name="input_vault_enterprise"></a>` [vault\_enterprise](#input\_vault\_enterprise)        | Whether using Vault Enterprise or not                                                                                          | `bool`   | `true`    |    no    |
| `<a name="input_vault_license"></a>` [vault\_license](#input\_vault\_license)                 | Vault Enterprise License as string                                                                                             | `string` | `"empty"` |    no    |
| `<a name="input_vault_version"></a>` [vault\_version](#input\_vault\_version)                 | Vault version expressed as X{n}.X{1,n}.X{1,n}, for example 1.16.3                                                              | `string` | n/a         |   yes   |

## Outputs

| Name                                                                                                  | Description          |
| ----------------------------------------------------------------------------------------------------- | -------------------- |
| `<a name="output_cluster1_fqdn_8200"></a>` [cluster1\_fqdn\_8200](#output\_cluster1\_fqdn\_8200)       | Outputs for cluster1 |
| `<a name="output_cluster1_fqdn_8201"></a>` [cluster1\_fqdn\_8201](#output\_cluster1\_fqdn\_8201)       | n/a                  |
| `<a name="output_cluster1_init_remote"></a>` [cluster1\_init\_remote](#output\_cluster1\_init\_remote) | n/a                  |
| `<a name="output_cluster2_fqdn_8200"></a>` [cluster2\_fqdn\_8200](#output\_cluster2\_fqdn\_8200)       | Outputs for cluster2 |
| `<a name="output_cluster2_fqdn_8201"></a>` [cluster2\_fqdn\_8201](#output\_cluster2\_fqdn\_8201)       | n/a                  |
| `<a name="output_cluster2_init_remote"></a>` [cluster2\_init\_remote](#output\_cluster2\_init\_remote) | n/a                  |
