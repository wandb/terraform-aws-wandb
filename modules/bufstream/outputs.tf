output "bucket_name" {
  description = "The name of the Bufstream storage bucket"
  value       = aws_s3_bucket.bufstream.id
}
