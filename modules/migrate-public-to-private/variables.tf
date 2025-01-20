variable "namespace" {
  type        = string
  description = "namespace for the project"
}

variable "subdomain" {
  type        = string
  description = "subdomain for the project"
}

variable "vpc_id" {
  type        = string
  description = "wandb VPC"
}

variable "vpc_cidr_block" {
  description = "value of the VPC CIDR block"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "list of subnets which are allowed to talk to ALB"
}

variable "private_hosted_zone_id" {
  description = "value of the private hosted zone id"
  type        = string
}
