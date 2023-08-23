data "aws_s3_bucket" "file_storage" {
  depends_on = [module.file_storage]
  bucket     = local.bucket_name
}

data "aws_sqs_queue" "file_storage" {
  count      = local.use_internal_queue ? 0 : 1
  depends_on = [module.file_storage]
  name       = local.bucket_queue_name
}