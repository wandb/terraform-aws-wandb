data "aws_s3_bucket" "file_storage" {
  depends_on = [module.file_storage]
  bucket     = local.main_bucket_name
}

data "aws_sqs_queue" "file_storage" {
  count      = local.use_internal_queue ? 0 : 1
  depends_on = [module.file_storage]
  name       = local.bucket_queue_name
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
