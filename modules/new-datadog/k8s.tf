resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

