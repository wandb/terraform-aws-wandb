output "service_name" {
  value = kubernetes_service.weave[0].metadata[0].name
}

output "service_port" {
  value = kubernetes_service.weave[0].spec.port.port
}

output "target_port" {
  value = kubernetes_service.weave[0].spec.port.target_port
}

output "service_type" {
  value = kubernetes_service.weave[0].spec.type
}
