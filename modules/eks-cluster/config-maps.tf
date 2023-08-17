resource "kubernetes_config_map" "config_map" {
  metadata {
    name = "wandb"
  }

  data = {
    "server_ca.pem" = var.redis_ca_cert
  }
}