variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "preferred_maintenance_window" {
  description = "(Optional) The weekly time range during which system maintenance can occur, in (UTC)"
  type        = string
  default     = "sun:03:00-sun:04:00"
}