# Install Secrets Store CSI Driver via Helm
resource "helm_release" "secrets_store_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = var.secrets_store_csi_driver_version
  namespace  = "kube-system"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "rotationPollInterval"
    value = "120s"
  }
}

# Install AWS Secrets Manager Provider for Secrets Store CSI Driver
resource "helm_release" "secrets_store_csi_driver_provider_aws" {
  depends_on = [
    helm_release.secrets_store_csi_driver
  ]

  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.secrets_store_csi_driver_provider_aws_version
  namespace  = "kube-system"
}

# SecretProviderClass for W&B internal secrets
# This configures the CSI driver to sync internal service auth secrets from AWS Secrets Manager to K8s Secrets
# Currently syncs: weave-worker-auth (can be extended for other internal services)
resource "kubernetes_manifest" "wandb_internal_secrets_provider" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "wandb-internal-secrets"
      namespace = var.k8s_namespace
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName = var.weave_worker_auth_secret_name
            objectType = "secretsmanager"
            jmesPath = [
              {
                path        = "."
                objectAlias = "weave-worker-auth"
              }
            ]
          }
        ])
      }
      secretObjects = [
        {
          secretName = "weave-worker-auth"
          type       = "Opaque"
          data = [
            {
              objectName = "weave-worker-auth"
              key        = "key"
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.secrets_store_csi_driver_provider_aws
  ]
}
