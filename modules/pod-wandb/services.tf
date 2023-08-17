resource "kubernetes_service" "prometheus" {
  metadata {
    name = "prometheus"
  }

  spec {
    selector = {
      app = "wandb"
    }
    port {
      name = "prometheus"
      port = 8181
    }
  }
}

resource "kubernetes_service" "wandb-8080" {
  metadata {
    name = "wandb-8080"
  }

  spec {
    selector = {
      app = "wandb"
    }
    port {
      name = "http-8080"
      port = 8080
    }
  }
}