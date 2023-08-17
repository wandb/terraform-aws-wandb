resource "kubernetes_priority_class" "priority" {
  metadata {
    name = "wandb-priority"
  }

  value          = 1000000000
  global_default = false
  description    = "Priority class for wandb pods."
}