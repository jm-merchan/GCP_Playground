In this first repo we are going to deploy the archetypical Vault Deployment as described in the [Raft Reference Architecture](https://developer.hashicorp.com/vault/tutorials/day-one-raft/raft-reference-architecture). There are many good examples of how to do this, modules included. One that is particularly nice and that I have used as reference is this one: [terraform-gcp-vault-starter](https://github.com/hashicorp/terraform-gcp-vault-starter). The module works as template or skeleton module that calls another set of specialized modules to create a number of resources: NLB, KMS, Secrets, Storage,... To simplify the work I have removed the nested structure to work with a single module.

The reference module created a number of Vault instances within a single-zone managed group, where Vault API is just accesible from within the VPC (this is the recomended approach). I have extended this structure to deploy not just an internal load balancer but also external load balancers. These load balancers provide access to the API (in a load-balancing function) and the cluster port (just pointing to the leader node of the raft cluster). **Optionally**, you can enable an extra load balancer to provide access to the KMIP default port. Allowing access to the cluster port is important as it allows for bulding replication relationships with secondary servers, whether those are used for Disaster Recovery (DR) or Performance Replicaton (PR) proposes

There are other changes are listed below:

* Let's encrypt generated certificate for Vault (with option to use production or staging CA).
* Inclusiong of Google Ops Agent in the VM to capture both audit logs and Promethus metrics. Part of the agent metric scrapping settings must be set "manually" after VM instances have been provisioned, as the Ops Agent required a Vault token to access a certain path within the API.
* Inclusion of log-rotate to rotate Vault audit logs.
* Steps to enable automatic snapshots
* Cluster Port Layer-4 load-balancer
* KMIP Layer-4 load-balancer
* Steps to initialize Vault and save the root token and recovery keys as GCP Secret.
