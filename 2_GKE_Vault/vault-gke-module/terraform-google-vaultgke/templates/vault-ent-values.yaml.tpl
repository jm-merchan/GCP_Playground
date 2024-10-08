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
   service:
      # https://cloud.google.com/kubernetes-engine/docs/concepts/service-load-balancer-parameters
      type: LoadBalancer
      sessionAffinity: "ClientIP"
      externalTrafficPolicy: Local
      annotations:
         cloud.google.com/load-balancer-type: "${expose}"
         # networking.gke.io/load-balancer-ip-addresses: _static_ip_
         # cloud.google.com/l4-rbs: "enabled"
   image:
      repository: docker.io/hashicorp/vault-enterprise
      tag: ${vault_version}
   enterpriseLicense:
      secretName: vault-ent-license
   extraEnvironmentVars:
      VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
      VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
      VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
      VAULT_SKIP_VERIFY: true  #THE ACME CERT DOES NOT INCLUDE 127.0.0.1 on its SAN so to avoid issues using the cli client adding this env
   volumes:
      - name: userconfig-vault-ha-tls
        secret:
         defaultMode: 420
         secretName: vault-ha-tls
      - name: logrotate-config
        configMap:
          name: logrotate-config
   volumeMounts:
      - mountPath: /vault/userconfig/vault-ha-tls
        name: userconfig-vault-ha-tls
        readOnly: true
   standalone:
      enabled: false
   serviceAccount:
      create: true
      annotations: |
         iam.gke.io/gcp-service-account: ${service_account}  # map vault sa to iam service account
   auditStorage:
      enabled: true
   # affinity: "" #No affinity rules so I can install 3 vault instances in a single
   affinity: |
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app.kubernetes.io/name: {{ template "vault.name" . }}
                app.kubernetes.io/instance: "{{ .Release.Name }}"
                component: server
            topologyKey: kubernetes.io/hostname
   
   statefulSet:
      securityContext:
         container: 
            runAsNonRoot: true
            runAsUser: 1000
            allowPrivilegeEscalation: false
            #capabilities:
            #   add: ["IPC_LOCK"]
   
   ha:
      enabled: true
      replicas: ${number_nodes}
      raft:
         enabled: true
         setNodeId: true
         config: |
            ui = true
            listener "tcp" {
               tls_disable                = 0 # Disabling TLS to avoid issues when connecting to Vault via port forwarding
               address                    = "[::]:8200"
               cluster_address            = "[::]:8201"
               tls_cert_file              = "/vault/userconfig/vault-ha-tls/vault.crt"
               tls_key_file               = "/vault/userconfig/vault-ha-tls/vault.key"
               tls_client_ca_file         = "/vault/userconfig/vault-ha-tls/vault.ca"
               tls_disable_client_certs   = true
   
            }
            storage "raft" {
               path = "/vault/data"
            
               retry_join {
                  auto_join             = "provider=k8s namespace=${namespace} label_selector=\"component=server,app.kubernetes.io/name={{ template "vault.name" . }}\""
                  auto_join_scheme      = "https"
                  leader_ca_cert_file   = "/vault/userconfig/vault-ha-tls/vault.ca"
                  leader_tls_servername = "${leader_tls_servername}"
               }
            
            }

            seal "gcpckms" {
               project    = "${project}"
               region     = "${location}"
               key_ring   = "${key_ring}"
               crypto_key = "${crypto_key}"
            }

            telemetry {
               disable_hostname                 = true
               prometheus_retention_time        = "12h"
               unauthenticated_metrics_access   = "true"
            }
            disable_mlock = true
            service_registration "kubernetes" {}
   
   # Vault UI
   ui:
      enabled: true
   
   # HUP signal for logrotate
   shareProcessNamespace: true
 
   # And finally the container
   extraContainers:
      - name: auditlog-rotator
        image: josemerchan/vault-logrotate:0.0.2
        imagePullPolicy: Always
        env:
         - name: CRONTAB
           value: "*/5 * * * *"
        volumeMounts:
         - mountPath: /etc/logrotate.conf
           name: logrotate-config
           subPath: logrotate.conf
           readOnly: true
         - mountPath: /vault/audit
           name: audit