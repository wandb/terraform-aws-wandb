resource "kubernetes_deployment" "parquet" {
  metadata {
    name = "parquet"
    labels = {
      app = "parquet"
    }
  }


  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "parquet"
      }
    }

    template {
      metadata {
        labels = {
          app = "parquet"
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
            name  = "ONLY_SERVICE"
            value = "gorilla-parquet"
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
            name = "MYSQL"
            value_from {
              secret_key_ref {
                name = "wandb"
                key  = "MYSQL"
              }
            }
          }

          env {
            name  = "HOST"
            value = var.fqdn
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
            name  = "REDIS"
            value = var.redis_connection_string
          }

          env {
            name  = "GORILLA_CUSTOM_METRICS_PROVIDER"
            value = var.cloud_monitoring_connection_string
          }

          env {
            name  = "WEAVE_SERVICE"
            value = "${var.weave_service_name}:9994"
          }

          env {
            name  = "PARQUET_ENABLED"
            value = "true"
          }

          env {
            name  = "WEAVE_ENABLED"
            value = "true"
          }

          dynamic "env" {
            for_each = var.other_wandb_env
            content {
              name  = env.key
              value = env.value

            }
          }

          env {
            name  = "GORILLA_STATSD_HOST"
            value = "datadog.datadog"
          }

          env {
            name  = "GORILLA_STATSD_PORT"
            value = "8125"
          }

          port {
            name           = "http"
            container_port = 8087
            protocol       = "TCP"
          }

          port {
            name           = "prometheus"
            container_port = 8181
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "3000m"
              memory = "12G"
            }
            limits = {
              cpu    = "3000m"
              memory = "12G"
            }
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