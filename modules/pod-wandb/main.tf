resource "kubernetes_deployment" "wandb" {
  metadata {
    name = "wandb"
    labels = {
      app = "wandb"
    }
  }

  spec {
    replicas                  = 1
    progress_deadline_seconds = 120

    strategy {
      type = "RollingUpdate"
    }

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
        priority_class_name = "wandb-priority"

        container {
          name              = "wandb"
          image             = "wandb:latest"
          image_pull_policy = "Always"

          volume_mount {
            mount_path = "/etc/ssl/certs/server_ca.pem"
            sub_path   = "server_ca.pem"
            name       = "wandb"
          }

          env {
            name  = "AUTH0_DOMAIN"
            value = var.auth0_domain
          }

          env {
            name  = "AUTH0_CLIENT_ID"
            value = var.auth0_client_id
          }

          env {
            name  = "AWS_S3_KMS_ID"
            value = var.s3_bucket_kms_key_arn
          }

          env {
            name  = "AWS_REGION"
            value = var.region
          }

          env {
            name  = "BUCKET"
            value = var.s3_bucket_name
          }

          env {
            name  = "BUCKET_QUEUE"
            value = var.s3_bucket_queue
          }

          env {
            name  = "HOST"
            value = var.fqdn
          }

          env {
            name  = "GORILLA_CUSTOM_METRICS_PROVIDER"
            value = var.cloud_monitoring_connection_string
          }

          env {
            name  = "LOCAL_RESTORE"
            value = var.local_restore
          }

          env {
            name  = "LICENSE"
            value = var.license
          }

          env {
            name = "MYSQL"
            value_from {
              secret_key_ref {
                name = "wandb"
                key  = "MYSQL"
              }
            }
          }

          env {
            name  = "OIDC_CLIENT_ID"
            value = var.oidc_client_id
          }

          env {
            name = "OIDC_SECRET"
            value_from {
              secret_key_ref {
                name = "wandb"
                key  = "OIDC_SECRET"
              }
            }
          }

          env {
            name  = "OIDC_AUTH_METHOD"
            value = var.oidc_auth_method
          }

          env {
            name  = "OIDC_ISSUER"
            value = var.oidc_issuer
          }

          env {
            name  = "PARQUET_ENABLED"
            value = "true"
          }

          env {
            name  = "PARQUET_HOST"
            value = "http://${var.parquet_service_name}:8087"
          }

          env {
            name  = "REDIS"
            value = var.redis_connection_string
          }

          env {
            name  = "WEAVE_ENABLED"
            value = "true"
          }

          env {
            name  = "WEAVE_SERVICE"
            value = "${var.weave_service_name}:9994"
          }



          dynamic "env" {
            for_each = var.other_wandb_env
            content {
              name  = env.key
              value = env.value

            }
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "prometheus"
            container_port = 8181
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
          startup_probe {
            http_get {
              path = "/ready"
              port = "http"
            }
            failure_threshold = 120
          }

          resources {
            requests = var.resource_requests
            limits   = var.resource_limits
          }
        }
        volume {
          name = "wandb"
          config_map {
            name     = "wandb"
            optional = true
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