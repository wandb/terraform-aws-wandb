resource "aws_vpc_endpoint" "endpoint" {
  vpc_id              = var.network_id
  service_name        = var.service_name
  vpc_endpoint_type   = "Gateway" 
  auto_accept = true
  route_table_ids  = var.private_route_table_id

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
