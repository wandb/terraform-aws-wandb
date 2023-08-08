data "aws_s3_bucket" "juicefs" {
  bucket = var.s3_bucket_name
}