variable "network_id" {
   type = string
   description = "ID of the network (VPC) where infrastructure resources will be deployed."
 }

variable "private_subnets" {
  type = string
  description = "Subnet ID within the specified network (VPC) where resources will be deployed"
}

variable "service_name" {
  type = string
  description = "Name of the service or vpc endpoint"
}