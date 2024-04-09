resource "aws_vpc_endpoint" "endpoint" {
  vpc_id              = var.network_id
  service_name        = var.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  dns_options {
    dns_record_ip_type                             = "ipv4"
    private_dns_only_for_inbound_resolver_endpoint = false
  }
  
  auto_accept = true
  subnet_ids  = [var.private_subnets]

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*",
      "Principal": "*"
    }
  ]
}
POLICY
}
