resource "kubernetes_deployment" "weave" {
  metadata {
    name = "weave"
    labels = {
      app = "weave"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weave"
      }
    }

    template {
      metadata {
        labels = {
          app = "weave"
        }
      }

      spec {
        priority_class_name = "wandb"

        container {
          name              = "weave"
          image             = "wandb:latest"
          image_pull_policy = "Always"

          env {
            name  = "ONLY_SERVICE"
            value = "weave"
          }

          env {
            name  = "WANDB_BASE_URL"
            value = var.fqdn
          }

          env {
            name  = "WEAVE_AUTH_GRAPHQL_URL"
            value = "${var.fqdn}/graphql"
          }

          env {
            name  = "DD_SERVICE"
            value = "weave-python"
          }

          env {
            name  = "DD_ENV"
            value = var.dd_env
          }

          dynamic "env" {
            for_each = ["DD_AGENT_HOST", "DD_TRACE_AGENT_HOSTNAME"]
            content {
              name = env.value
              value_from {
                field_ref {
                  field_path = "status.hostIP"
                }
              }
            }
          }

          env {
            name  = "WEAVE_ENABLE_DATADOG"
            value = "true"
          }

          env {
            name  = "DD_PROFILING_ENABLED"
            value = "true"
          }

          port {
            name           = "http"
            container_port = 9994
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "__weave/hello"
              port = "http"
            }
          }

          readiness_probe {
            http_get {
              path = "__weave/hello"
              port = "http"
            }
          }

          startup_probe {
            http_get {
              path = "__weave/hello"
              port = "http"
            }
            failure_threshold = 12
            period_seconds    = 10
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1G"
            }
            limits = {
              cpu    = "8000m"
              memory = "16G"
            }
          }
        }
      }
    }
  }
}