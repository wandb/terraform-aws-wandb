variable "namespace" {
  type        = string
  default = "lsahu-eks"
  description = "Name prefix used for resources"
}

variable "domain_name" {
  type        = string
  default = "wandb.ml"
  description = "Domain name used to access instance."
}

variable "wandb_license" {
  type        = string
  description = "License key for Weights & Biases"
  default     = "eyJhbGciOiJSUzI1NiIsImtpZCI6InUzaHgyQjQyQWhEUXM1M0xQY09yNnZhaTdoSlduYnF1bTRZTlZWd1VwSWM9In0.eyJjb25jdXJyZW50QWdlbnRzIjoxMCwiZGVwbG95bWVudElkIjoiMTBiYzY1MWEtYzQwNC00MmU1LThiMDktOGY5ZTE4NDNhMWQ2IiwibWF4VXNlcnMiOjEwMCwibWF4Vmlld09ubHlVc2VycyI6MCwibWF4U3RvcmFnZUdiIjoxMDAwLCJtYXhUZWFtcyI6MTAwMCwibWF4UmVnaXN0ZXJlZE1vZGVscyI6MiwiZXhwaXJlc0F0IjoiMjAyNi0wMS0zMVQwNTo1OTo1OS45OTlaIiwiZmxhZ3MiOlsiU0NBTEFCTEUiLCJteXNxbCIsInMzIiwicmVkaXMiLCJOT1RJRklDQVRJT05TIiwic2xhY2siLCJub3RpZmljYXRpb25zIiwiTUFOQUdFTUVOVCIsIm9yZ19kYXNoIiwiYXV0aDAiLCJjb2xsZWN0X2F1ZGl0X2xvZ3MiLCJyYmFjIiwiQllPQiIsImJ5b2IiLCJFTkZPUkNFX0xJTUlUUyIsImVuZm9yY2VfdXNlcl9saW1pdCIsIkxBVU5DSF9DTFVTVEVSUyIsImxhdW5jaF9jbHVzdGVycyJdLCJ0cmlhbCI6ZmFsc2UsImNvbnRyYWN0U3RhcnREYXRlIjoiMjAyNS0wMS0yOVQwNjowMDowMC4wMDBaIiwiYWNjZXNzS2V5IjoiZTUwMjI1ODAtMjEyZS00MjNkLWI5MzYtMDNhZDFkOTA3MTJiIiwic2VhdHMiOjEwMCwidmlld09ubHlTZWF0cyI6MCwidGVhbXMiOjEwMDAsInJlZ2lzdGVyZWRNb2RlbHMiOjIsInN0b3JhZ2VHaWdzIjoxMDAwLCJleHAiOjE3Njk4MzkxOTksIndlYXZlTGltaXRzIjp7IndlYXZlTGltaXRCeXRlcyI6MTAwMDAwMDAwMDAwMCwid2VhdmVPdmVyYWdlQ29zdENlbnRzIjowLCJ3ZWF2ZU92ZXJhZ2VVbml0IjoiTUIifX0.V5vD5o7jlRBIWquLd7_WthWX7S38EH2FbSmqzZ7wTdd_kbs6cCGxNuia3I_zDVuRsvIfL9IK7KUp8RKXKRiWgUAge4P1mu0FMZ_nsqV8-e4dCOXpPdjqhQ5u_AbzhM26QljTcpLr1jnNPpBFtO4_C3kUeHv4gq7CvF3n8RJIPm1w1_plWyqqZq4Y0kKzbJhEz4ji0dMwcy4tQEQo1qM2MBbvPltJOe-YugbK0jBBtGaNX7LwfqKYATexclizbROj8TKkmmjl2U3LegjniGmYl6E4XMX3Vm_MsUf8zhtZ-qavOYaQzLVVcD8-FAEht_FymmM-mUYAqy41xUjouXF_nw"
}
variable "zone_id" {
  type        = string
  description = "Id of Route53 zone"
  default = "Z05539563M7J8OK1FQMSA"
}

variable "size" {
  default     = "small"
  description = "Deployment size"
  nullable    = true
  type        = string
}

variable "subdomain" {
  type        = string
  default     = "lsahu-eks"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.05.2"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance."
  type        = string
  default     = "db.r5.large"
}

variable "database_snapshot_identifier" {
  description = "Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot"
  type        = string
  default     = null
}

variable "database_sort_buffer_size" {
  description = "Specifies the sort_buffer_size value to set for the database"
  type        = number
  default     = 262144
}

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "bucket_kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  default     = ""
}

variable "bucket_path" {
  description = "path of where to store data for the instance-level bucket"
  type        = string
  default     = ""
}

variable "allowed_inbound_cidr" {
  default  = ["0.0.0.0/0"]
  nullable = false
  type     = list(string)
}


variable "allowed_inbound_ipv6_cidr" {
  default  = ["::/0"]
  nullable = false
  type     = list(string)
}

variable "other_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "system_reserved_cpu_millicores" {
  description = "(Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_memory_megabytes" {
  description = "(Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_ephemeral_megabytes" {
  description = "(Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_pid" {
  description = "(Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "aws_loadbalancer_controller_tags" {
  description = "(Optional) A map of AWS tags to apply to all resources managed by load balancer and cluster"
  type        = map(string)
  default     = {}
}

variable "create_elasticache" {
  type        = bool
  default     = true
  description = "whether to create an elasticache redis"
}
