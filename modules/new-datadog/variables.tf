variable "cluster_name" {
  nullable = false
  type     = string
}

variable "api_key" {
  nullable = true
  type     = string
}

variable "app_key" {
  nullable = true
  type     = string
}

variable "site" {
  nullable = true
  type     = string
}

variable "k8s_cluster_ca_certificate" {
  nullable = false
  type     = string
}

variable "k8s_host" {
  nullable = false
  type     = string
}

variable "k8s_token" {
  nullable = false
  type     = string
}

variable "namespace" {
  description = "The name prefix for all resources created."
  nullable    = false
  type        = string
}