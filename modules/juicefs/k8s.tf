resource "kubernetes_namespace" "juicefs" {
  metadata {
    name = "juicefs"
  }
}


resource "kubernetes_secret" "juicefs" {
  depends_on = [kubernetes_namespace.juicefs]

  metadata {
    name      = "juicefs-secret"
    namespace = "juicefs"
  }

  data = {
    name : "juicefs"
    metaurl : "${local.metastore_url}"
    storage : "s3"
    bucket : "${local.objectstore_url}"
    access-key : "${aws_iam_access_key.juicefs.id}"
    secret-key : "${aws_iam_access_key.juicefs.secret}"
    secret-key-enc : "${aws_iam_access_key.juicefs.encrypted_secret}"
    format-options : "compress=lz4"
    mount-options : "cache-size=16384"
  }

  type = "Opaque"
}

