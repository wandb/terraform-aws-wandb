resource "helm_release" "crds" {
  depends_on = [kubernetes_namespace.datadog]

  chart            = "datadog-crds"
  cleanup_on_fail  = true
  create_namespace = false
  force_update     = true
  lint             = true
  name             = "datadog-crds"
  namespace        = "datadog"
  recreate_pods    = true
  repository       = "https://helm.datadoghq.com"
  version          = "1.1.0"
  wait             = true
  wait_for_jobs    = true  

  lifecycle {
    create_before_destroy = false
  }

  values = [templatefile("${path.module}/datadog-crds.tftpl",
    {
      agents      = true
      metrics     = true
      monitors    = true
  })]
}  

resource "helm_release" "extendeddaemonset" {
  depends_on = [kubernetes_namespace.datadog, helm_release.crds]


  chart            = "extendeddaemonset"
  cleanup_on_fail  = true
  create_namespace = false
  force_update     = true
  lint             = true
  name             = "datadog-extendeddaemonset"
  namespace        = "datadog"
  recreate_pods    = true
  repository       = "https://helm.datadoghq.com"
  version          = "0.2.2"
  wait             = true
  wait_for_jobs    = true  

  lifecycle {
    create_before_destroy = false
  }

  values = [templatefile("${path.module}/datadog-extendeddaemonset.tftpl",
    {
      installCRDs  = true
  })]
} 


resource "helm_release" "datadog" {
  depends_on = [kubernetes_namespace.datadog, helm_release.crds, helm_release.extendeddaemonset]

  chart            = "datadog"
  cleanup_on_fail  = true
  create_namespace = false
  force_update     = true
  lint             = true
  name             = "datadog"
  namespace        = "datadog"
  recreate_pods    = true
  repository       = "https://helm.datadoghq.com"
  version          = "3.36.2"
  wait             = true
  wait_for_jobs    = true

  lifecycle {
    create_before_destroy = false
  }

  values = [templatefile("${path.module}/datadog-agent.tftpl",
    {
      api_key = "${var.api_key}"
      app_key = "${var.app_key}"
      cloud_provider_tag = "${var.cloud_provider_tag}"
      database_tag = "${var.database_tag}"
      environment_tag = "${var.environment_tag}"
      namespace_tag = "${var.namespace}"
      objectstore_tag = "${var.objectstore_tag}"
      site = "${var.site}"
  })]
}