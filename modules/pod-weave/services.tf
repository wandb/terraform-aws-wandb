resource "kubernetes_service" "weave" {
  metadata {
    name = "weave"
  }

  spec {
    type = "NodePort"
    selector = {
      app = "weave"
    }
    port {
      name        = "http"
      port        = 9994
      target_port = 9994
    }
  }
}