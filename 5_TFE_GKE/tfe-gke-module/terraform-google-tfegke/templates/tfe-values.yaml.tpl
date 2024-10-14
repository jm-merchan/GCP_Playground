replicaCount: 1

tls:
  certData: "${certData}"
  keyData: "${keyData}"
  caCertData: "${caCertData}"

service:
   type: LoadBalancer # ClusterIP
   ports:
    - name: https-443
      port: 443
      protocol: TCP
      targetPort: 8443
   sessionAffinity: "ClientIP"
   externalTrafficPolicy: Local
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

    # Database settings.
    TFE_DATABASE_HOST: "${TFE_DATABASE_HOST}"
    TFE_DATABASE_NAME: "${TFE_DATABASE_NAME}"
    # TFE_DATABASE_PARAMETERS: <Database extra params e.g "sslmode=require">
    TFE_DATABASE_USER: "${TFE_DATABASE_USER}"

    # Redis settings.
    TFE_REDIS_HOST: "${TFE_REDIS_HOST}"
    #TFE_REDIS_USE_TLS: <To use tls? eg. "false">
    #TFE_REDIS_USE_AUTH: <To use customized credential to authenticate? eg. "true">
    #TFE_REDIS_USER: <Redis username>

    # Google Cloud Storage settings.
    TFE_OBJECT_STORAGE_TYPE: google
    TFE_OBJECT_STORAGE_GOOGLE_BUCKET: "${TFE_OBJECT_STORAGE_GOOGLE_BUCKET}"
    TFE_OBJECT_STORAGE_GOOGLE_PROJECT: "${TFE_OBJECT_STORAGE_GOOGLE_PROJECT}"
    TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID: "${TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID}"
    # TFE_OBJECT_STORAGE_S3_ENDPOINT: ""
    # TFE_OBJECT_STORAGE_S3_REGION: ""
  secrets:
    TFE_DATABASE_PASSWORD: "${TFE_DATABASE_PASSWORD}"
    TFE_OBJECT_STORAGE_GOOGLE_CREDENTIALS: "${TFE_OBJECT_STORAGE_GOOGLE_CREDENTIALS}"
    #TFE_REDIS_PASSWORD: '<Redis password>'
    TFE_LICENSE: "${TFE_LICENSE}"
    TFE_ENCRYPTION_PASSWORD: 'Password123!'
