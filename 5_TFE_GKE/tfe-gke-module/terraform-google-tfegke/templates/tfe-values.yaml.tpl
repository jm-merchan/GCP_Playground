replicaCount: 1

#resources:
#   requests:
#      memory: 1024Mi
#      cpu: 500m
#   limits:
#      memory: 1024Mi
#      cpu: 500m
  
tls:
   certData: ${certData}
   keyData: ${keyData}
   caCertData: ${caCertData}

service:
   type: LoadBalancer # ClusterIP
   ports:
   - name: https-443
     port: 443
     protocol: TCP
     targetPort: 8443
   annotations: 
      cloud.google.com/load-balancer-type: "External"


image:
   repository: images.releases.hashicorp.com
   name: hashicorp/terraform-enterprise
   tag: "${TFE_VERSION}"
   serviceAccount:
      enabled: true
      annotations: |
         iam.gke.io/gcp-service-account: ${service_account} 
env:
   variables:
      TFE_HOSTNAME: "${TFE_HOSTNAME}"
      TFE_IACT_SUBNETS: "${TFE_IACT_SUBNETS}"
      TFE_IACT_TIME_LIMIT: 120
      TFE_METRICS_ENABLE: true
      TFE_OPERATIONAL_MODE: "external"

      # Database settings.
      TFE_DATABASE_HOST: "${TFE_DATABASE_HOST}"
      TFE_DATABASE_NAME: "${TFE_DATABASE_NAME}"
      # TFE_DATABASE_PARAMETERS: <Database extra params e.g "sslmode=require">
      TFE_DATABASE_USER: "${TFE_DATABASE_USER}"
      TFE_DATABASE_RECONNECT_ENABLED: true

      # Redis settings.
      TFE_REDIS_HOST: "${TFE_REDIS_HOST}"

      # Google Cloud Storage settings.
      TFE_OBJECT_STORAGE_TYPE: google
      TFE_OBJECT_STORAGE_GOOGLE_BUCKET: "${TFE_OBJECT_STORAGE_GOOGLE_BUCKET}"
      TFE_OBJECT_STORAGE_GOOGLE_PROJECT: "${TFE_OBJECT_STORAGE_GOOGLE_PROJECT}"

   secrets:
      TFE_DATABASE_PASSWORD: "${TFE_DATABASE_PASSWORD}"
      TFE_OBJECT_STORAGE_GOOGLE_CREDENTIALS: "${TFE_OBJECT_STORAGE_GOOGLE_CREDENTIALS}"
      TFE_LICENSE: "${TFE_LICENSE}"
      TFE_ENCRYPTION_PASSWORD: "Password123"
