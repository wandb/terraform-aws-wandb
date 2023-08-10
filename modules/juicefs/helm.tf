locals {
  objectstore_url = "https://${data.aws_s3_bucket.juicefs.bucket_domain_name}/juicefs"
  metastore_url   = "rediss://${aws_elasticache_user.juicefs.user_name}:${random_password.juicefs.result}@${aws_elasticache_replication_group.juicefs.configuration_endpoint_address}:${aws_elasticache_replication_group.juicefs.port}/1"

}


resource "helm_release" "juicefs-csi-driver" {
  depends_on = [kubernetes_secret.juicefs]

  #atomic           = true
  chart            = "juicefs-csi-driver"
  cleanup_on_fail  = true
  create_namespace = false
  #force_update     = true
  name      = "juicefs-csi-driver"
  namespace = "juicefs"
  #recreate_pods    = true
  repository = "https://juicedata.github.io/charts/"
  version    = "0.17.2"
  #wait_for_jobs    = true

  values = [templatefile("${path.module}/csi-values.tftpl",
    {
      accessKey = "${aws_iam_access_key.juicefs.id}",
      bucket_url    = "${local.objectstore_url}",
      metastore_url   = "${local.metastore_url}",
      secretKey = "${aws_iam_access_key.juicefs.secret}",
  })]
}


