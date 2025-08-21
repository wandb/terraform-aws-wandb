resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  chart      = "external-dns"
  version    = "1.15.0"
  repository = "https://kubernetes-sigs.github.io/external-dns"

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "domainFilters[0]"
    value = var.fqdn
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "interval"
    value = "5m"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.default.arn
  }

  set {
    name  = "image.repository"
    value = var.external_dns_image_repository
  }

  dynamic "set" {
    for_each = var.external_dns_image_tag != null ? [var.external_dns_image_tag] : []
    content {
      name  = "image.tag"
      value = set.value
    }
  }
}
