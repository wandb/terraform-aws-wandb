locals {
  objectstore_url = "https://${data.aws_s3_bucket.juicefs.bucket_domain_name}/juicefs"
  metastore_url   = "redis://${aws_elasticache_user.juicefs.user_name}:${random_password.juicefs.result}@${aws_elasticache_replication_group.juicefs.configuration_endpoint_address}/1"

}

resource "helm_release" "juicefs" {
  depends_on = [kubernetes_secret.juicefs]

  atomic           = true
  chart            = "juicefs"
  cleanup_on_fail  = true
  create_namespace = false
  force_update     = true
  name             = "juicefs"
  namespace        = "juicefs"
  recreate_pods    = true
  repository       = "https://juicedata.github.io/charts/"
  version          = "0.17.2"
  wait_for_jobs    = true

  set {
    name  = "controller.leaderElection.leaderElectionNamespace"
    value = "juicefs"
  }

  set {
    name  = "controller.provisioner"
    value = true
  }


  set {
    name  = "node.enabled"
    value = true
  }

  set {
    name  = "node.storageClassShareMount"
    value = true
  }

  set {
    name  = "storageClasses[0].allowVolumeExpansion"
    value = true
  }

  set {
    name  = "storageClass[0].backend.accessKey"
    value = aws_iam_access_key.juicefs.id
  }

  set {
    name  = "storageClass[0].backend.bucket"
    value = local.objectstore_url
  }

  set {
    name  = "storageClass.backend[0].formatOptions"
    value = "compress=lz4,dir-stats=true,repair=true,strict=true"
  }

  set {
    name  = "storageClasses.backend[0].metaurl"
    value = local.metastore_url
  }

  set {
    name  = "storageClasses.backend[0].name"
    value = "juicefs"
  }

  set {
    name  = "sotrageClass.backend[0].secretKey"
    value = aws_iam_access_key.juicefs.encrypted_secret
  }

  set {
    name  = "storageClass.backend[0].storage"
    value = "s3"
  }

  set {
    name  = "storageClass.backend[0].trashDays"
    value = 1
  }

  set_list {
    name  = "hostAliases.ip"
    value = ["127.0.0.1"]
  }

  set_list {
    name  = "hostAliases.hostnames"
    value = ["s3.juicefs.local", "redis.juicefs.local"]
  }

  set {
    name  = "storageClass[0].mountOptions"
    value = "cachesize=4096"
  }

  set {
    name  = "storageClass.enabled"
    value = true
  }
}



