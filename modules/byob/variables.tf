variable "wandb_deployment_account_id" {
  type        = string
  default     = "830241207209"
  description = "Weights & Biases deployment account"
}

variable "bucket_prefix" {
  type    = string
  default = "Prefix used for the bucket."
}

variable "kms_key_arn" {
  type    = object({ key_id = string, arn = string })
  default = null
}
