resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

resource "kubernetes_secret" "datadog" {
  depends_on = [kubernetes_namespace.datadog]
  type       = "Opaque"
  metadata {
    name      = "datadog-secrets"
    namespace = "datadog"
  }

  data = {
    "api-key" = var.dd_api_key
    "app-key" = var.dd_app_key
  }
}

resource "random_id" "k8s_token_hash" {
  keepers = {
    k8s_token = var.k8s_token
  }

  byte_length = 8
}