locals {
  domain_filters = concat(
    [{ name = "domainFilters[0]", value = var.fqdn }],
    [for san in var.subject_alternative_names : { name = "domainFilters[${index(var.subject_alternative_names, san) + 1}]", value = san }]
  )
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  chart      = "external-dns"
  version    = "1.14.1"
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

  dynamic "set" {
    for_each = local.domain_filters

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.default.arn
  }


}
