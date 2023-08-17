resource "kubernetes_service" "parquet" {
  metadata {
    name = "parquet"
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "parquet"
    }
    port {
      name        = "http"
      port        = 8087
      target_port = 8087
    }
  }
}