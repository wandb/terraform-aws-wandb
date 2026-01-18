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

# NOTE: The SecretProviderClass is created by the application Helm chart (operator-wandb),
# not by Terraform. This avoids CRD timing issues and keeps application-specific configuration
# with the application deployment.
