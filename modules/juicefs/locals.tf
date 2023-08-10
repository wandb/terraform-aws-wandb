locals {
  objectstore_url = "https://${data.aws_s3_bucket.juicefs.bucket_domain_name}/juicefs"
  metastore_url   = "rediss://${var.elasticache_user}:${var.elasticache_password}@${aws_elasticache_replication_group.juicefs.configuration_endpoint_address}:${aws_elasticache_replication_group.juicefs.port}/1"
}