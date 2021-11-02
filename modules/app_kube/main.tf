resource "kubernetes_deployment" "wandb" {
  metadata {
    name = "wandb"
    labels = {
      app = "wandb"
    }
  }

  spec {
    strategy {
      type = "RollingUpdate"
    }

    replicas = 1

    selector {
      match_labels = {
        app = "wandb"
      }
    }

    template {
      metadata {
        labels = {
          app = "wandb"
        }
      }

      spec {
        container {
          name              = "wandb"
          image             = "wandb/local:${var.local_version}"
          image_pull_policy = "Always"

          env {
            name  = "LICENSE"
            value = var.local_license
          }
          env {
            name  = "BUCKET"
            value = "s3://${var.bucket_name}"
          }
          env {
            name  = "BUCKET_QUEUE"
            value = "sqs://${var.bucket_queue_name}"
          }
          env {
            name  = "AWS_REGION"
            value = var.bucket_region
          }
          env {
            name  = "MYSQL"
            value = "mysql://${var.database_endpoint}"
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "http"
            }
          }

          resources {
            requests = {
              cpu    = "1500m"
              memory = "4G"
            }
            limits = {
              cpu    = "4000m"
              memory = "8G"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wandb_service" {
  metadata {
    name = "wandb"
  }

  spec {
    type = "NodePort"
    selector = {
      app = "wandb"
    }
    port {
      port      = 8080
      node_port = 32543
    }
  }
}