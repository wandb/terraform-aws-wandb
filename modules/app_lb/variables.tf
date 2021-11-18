
variable "namespace" {
  type        = string
  description = "(Required) String used for prefix resources."
}

variable "acm_certificate_arn" {
  type        = string
  description = "(Optional) The ARN of an existing ACM certificate."
  default     = null
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  description = "(Optional) SSL policy to use on ALB listener"
}

variable "zone_id" {
  type        = string
  description = "(Required) The zone ID of the route53 to create the application A record in."
}

variable "fqdn" {
  type        = string
  description = "(Required) Fully qualified domain name."
}

variable "load_balancing_scheme" {
  default     = "PRIVATE"
  description = "(Optional) Load Balancing Scheme. Supported values are: \"PRIVATE\"; \"PUBLIC\"."
  type        = string

  validation {
    condition     = contains(["PRIVATE", "PUBLIC"], var.load_balancing_scheme)
    error_message = "The load_balancer_scheme value must be one of: \"PRIVATE\"; \"PUBLIC\"."
  }
}

variable "allowed_inbound_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "(Optional) Allow HTTP(S) traffic to W&B. Defaults to all connections."
}

variable "allowed_inbound_ipv6_cidr" {
  type        = list(string)
  default     = ["::/0"]
  description = "(Optional) Allow HTTP(S) traffic to W&B. Defaults to all connections."
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "network_public_subnets" {
  default     = []
  description = "(Optional) A list of the identities of the public subnetworks in which resources will be deployed."
  type        = list(string)
}

variable "target_port" {
  type    = number
  default = 32543
}