variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "aws_loadbalancer_controller_tags" {
  type = map(string)
}

variable "aws_loadbalancer_controller_image" {
  type        = string
  description = "The image repository of the aws-loadbalancer-controller to deploy."
  default     = "public.ecr.aws/eks/aws-load-balancer-controller"
}

variable "aws_loadbalancer_controller_version" {
  type        = string
  description = "The tag of the aws-loadbalancer-controller to deploy."
  default     = null
}
