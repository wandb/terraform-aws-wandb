variable "trusted_account_id" {
  type = string
}

# Bucket we would like to give access too
variable "bucket_arn" {
  type = string
}

# The SQS we would like to give access too
variable "bucket_sqs_queue_arn" {
  type = string
}