variable "namespace" {
  type        = string
  default = "lsahu-eks"
  description = "Name prefix used for resources"
}

variable "domain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
  default     = "eyJhbGciOiJSUzI1NiIsImtpZCI6InUzaHgyQjQyQWhEUXM1M0xQY09yNnZhaTdoSlduYnF1bTRZTlZWd1VwSWM9In0.eyJjb25jdXJyZW50QWdlbnRzIjoxMCwiZGVwbG95bWVudElkIjoiMTBiYzY1MWEtYzQwNC00MmU1LThiMDktOGY5ZTE4NDNhMWQ2IiwibWF4VXNlcnMiOjEwMCwibWF4Vmlld09ubHlVc2VycyI6MCwibWF4U3RvcmFnZUdiIjoxMDAwLCJtYXhUZWFtcyI6MTAwMCwibWF4UmVnaXN0ZXJlZE1vZGVscyI6MiwiZXhwaXJlc0F0IjoiMjAyNi0wMS0zMVQwNTo1OTo1OS45OTlaIiwiZmxhZ3MiOlsiU0NBTEFCTEUiLCJteXNxbCIsInMzIiwicmVkaXMiLCJOT1RJRklDQVRJT05TIiwic2xhY2siLCJub3RpZmljYXRpb25zIiwiTUFOQUdFTUVOVCIsIm9yZ19kYXNoIiwiYXV0aDAiLCJjb2xsZWN0X2F1ZGl0X2xvZ3MiLCJyYmFjIiwiQllPQiIsImJ5b2IiLCJFTkZPUkNFX0xJTUlUUyIsImVuZm9yY2VfdXNlcl9saW1pdCIsIkxBVU5DSF9DTFVTVEVSUyIsImxhdW5jaF9jbHVzdGVycyJdLCJ0cmlhbCI6ZmFsc2UsImNvbnRyYWN0U3RhcnREYXRlIjoiMjAyNS0wMS0yOVQwNjowMDowMC4wMDBaIiwiYWNjZXNzS2V5IjoiZTUwMjI1ODAtMjEyZS00MjNkLWI5MzYtMDNhZDFkOTA3MTJiIiwic2VhdHMiOjEwMCwidmlld09ubHlTZWF0cyI6MCwidGVhbXMiOjEwMDAsInJlZ2lzdGVyZWRNb2RlbHMiOjIsInN0b3JhZ2VHaWdzIjoxMDAwLCJleHAiOjE3Njk4MzkxOTksIndlYXZlTGltaXRzIjp7IndlYXZlTGltaXRCeXRlcyI6MTAwMDAwMDAwMDAwMCwid2VhdmVPdmVyYWdlQ29zdENlbnRzIjowLCJ3ZWF2ZU92ZXJhZ2VVbml0IjoiTUIifX0.V5vD5o7jlRBIWquLd7_WthWX7S38EH2FbSmqzZ7wTdd_kbs6cCGxNuia3I_zDVuRsvIfL9IK7KUp8RKXKRiWgUAge4P1mu0FMZ_nsqV8-e4dCOXpPdjqhQ5u_AbzhM26QljTcpLr1jnNPpBFtO4_C3kUeHv4gq7CvF3n8RJIPm1w1_plWyqqZq4Y0kKzbJhEz4ji0dMwcy4tQEQo1qM2MBbvPltJOe-YugbK0jBBtGaNX7LwfqKYATexclizbROj8TKkmmjl2U3LegjniGmYl6E4XMX3Vm_MsUf8zhtZ-qavOYaQzLVVcD8-FAEht_FymmM-mUYAqy41xUjouXF_nw"
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