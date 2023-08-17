resource "kubernetes_secret" "secret" {
  metadata {
    name = "wandb"
  }

  data = {
    "MYSQL"       = var.database_connection_string
    "OIDC_SECRET" = var.oidc_secret
  }
}