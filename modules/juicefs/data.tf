data "aws_iam_access_keys" "juicefs" {
  user = aws_iam_user.juicefs.name
}

data "aws_s3_bucket" "juicefs" {
  bucket = var.s3_bucket_name
}

# data "template_file" "csi-values" {
#   template = file("${module.path}/csi-values.tfptl")
#   vars = {
#     "accessKey" = "${aws_iam_access_key.juicefs.id}",
#     "bucket"    = "${local.objectstore_url}",
#     "metaurl"   = "${local.metastore_url}",
#   }
# }