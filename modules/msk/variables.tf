variable "namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "instance_type" {
  type    = string
  default = "kafka.m5.large"
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "kafka_version" {
  type    = string
  default = "3.6.0"
}