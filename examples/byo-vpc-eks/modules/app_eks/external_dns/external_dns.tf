resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  chart      = "external-dns"
  version    = "1.15.0"
  repository = "https://kubernetes-sigs.github.io/external-dns"

  values = [<<EOT
  txtPrefix: ""
  txtSuffix: ""
rbac:
  create: true
serviceAccount:
  create: true
  name: external-dns
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.default.arn}
domainFilters:
  - ${var.fqdn}
policy: sync
interval: 5m
EOT
  ]
}
