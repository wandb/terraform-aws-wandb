locals {
  app_name = "wandb"
}
resource "kubernetes_deployment" "wandb" {
  metadata {
    name = local.app_name
    labels = {
      app = local.app_name
    }
  }

  spec {
    replicas                  = 1
    progress_deadline_seconds = 3600

    strategy {
      type = "RollingUpdate"
    }

    selector {
      match_labels = {
        app = local.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.app_name
        }
      }

      spec {
        container {
          name              = local.app_name
          image             = "${var.wandb_image}:${var.wandb_version}"
          image_pull_policy = "Always"

          env {
            name  = "LICENSE"
            value = var.wandb_license
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
            value = "mysql://${var.database_connection_string}"
          }

          env {
            name  = "AWS_S3_KMS_ID"
            value = var.bucket_kms_key_arn
          }

          env {
            name  = "HOST"
            value = var.host
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
            period_seconds = 900
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

  timeouts {
    create = "1h"
    update = "1h"
    delete = "10m"
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = local.app_name
  }

  spec {
    type = "NodePort"
    selector = {
      app = local.app_name
    }
    port {
      port      = 8080
      node_port = var.service_port
    }
  }
}