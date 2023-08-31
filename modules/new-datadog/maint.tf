resource "helm_release" "datadog" {
  chart            = "datadog"
  cleanup_on_fail  = true
  create_namespace = false
  force_update     = true
  name             = "datadog"
  namespace        = "datadog"
  recreate_pods    = true
  repository       = "https://helm.datadoghq.com"
  version          = "3.33.7"
  wait             = true
  wait_for_jobs    = true

  depends_on = [kubernetes_secret.datadog]
  lifecycle {
    create_before_destroy = false
    replace_triggered_by  = [random_id.k8s_token_hash]
  }

  values = [templatefile("${path.module}/datadog.tftpl",
    {
      dd_site = "${var.dd_site}",
  })]
}