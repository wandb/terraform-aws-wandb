locals {
  objectstore_url = "https://${data.aws_s3_bucket.juicefs.bucket_regional_domain_name}"
  metastore_url   = "rediss://:${var.elasticache_password}@${aws_elasticache_replication_group.juicefs.configuration_endpoint_address}:${aws_elasticache_replication_group.juicefs.port}/1"
}