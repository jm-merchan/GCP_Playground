global:
   enabled: true
   tlsDisable: false 

injector:
   enabled: true
   image:
      repository: docker.io/hashicorp/vault-k8s
   agentImage:
      repository: docker.io/hashicorp/vault

# Supported log levels include: trace, debug, info, warn, error
logLevel: "trace" # Set to trace for initial troubleshooting, info for normal operation

server:
# config.yaml
   image:
      repository: docker.io/hashicorp/vault-enterprise
      tag: ${vault_version}
   enterpriseLicense:
      secretName: vault-ent-license
   extraEnvironmentVars:
      VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
      VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
      VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
   volumes:
      - name: userconfig-vault-ha-tls
        secret:
         defaultMode: 420
         secretName: vault-ha-tls
   volumeMounts:
      - mountPath: /vault/userconfig/vault-ha-tls
        name: userconfig-vault-ha-tls
        readOnly: true
   standalone:
      enabled: false
   # affinity: "" #No affinity rules so I can install 3 vault instances in a single
   serviceAccount:
      create: true
      annotations: |
         iam.gke.io/gcp-service-account: ${service_account}
   affinity: |
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app.kubernetes.io/name: {{ template "vault.name" . }}
                app.kubernetes.io/instance: "{{ .Release.Name }}"
                component: server
            topologyKey: kubernetes.io/hostname
   ha:
      enabled: true
      replicas: 3
      raft:
         enabled: true
         setNodeId: true
         config: |
            ui = true
            listener "tcp" {
               tls_disable = 0 # Disabling TLS to avoid issues when connecting to Vault via port forwarding
               address = "[::]:8200"
               cluster_address = "[::]:8201"
               tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
               tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
               tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
   
            }
            storage "raft" {
               path = "/vault/data"
            
               retry_join {
                  auto_join             = "provider=k8s namespace=${namespace} label_selector=\"component=server,app.kubernetes.io/name={{ template "vault.name" . }}\""
                  auto_join_scheme      = "https"
                  leader_ca_cert_file   = "/vault/userconfig/vault-ha-tls/vault.ca"
                  leader_tls_servername = "${leader_tls_servername}" #Tiene que matchear una SAN del certificado
               }
            
            }

            seal "gcpckms" {
               project    = "${project}"
               region     = "${location}"
               key_ring   = "${key_ring}"
               crypto_key = "${crypto_key}"
            }

            telemetry {
               disable_hostname = true
               prometheus_retention_time = "12h"
            }
            disable_mlock = true
            service_registration "kubernetes" {}
      # Vault UI
   ui:
      enabled: true
      serviceType: "LoadBalancer"
      serviceNodePort: null
      externalPort: 8200