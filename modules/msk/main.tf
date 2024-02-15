# Security group for MSK (allows traffic within your VPC)
resource "aws_security_group" "msk" {
  name        = "${var.namespace}-msk-sg"
  vpc_id      = var.vpc_id
  description = "Allow MSK traffic within the VPC"

  ingress {
    from_port = 9092
    to_port   = 9092
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_msk_cluster" "default" {
  cluster_name           = var.namespace
  kafka_version          = "3.6.0"
  number_of_broker_nodes = length(var.private_subnets)

  broker_node_group_info {
    instance_type = "kafka.m5.large"

    client_subnets  = var.private_subnets
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = 20
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
    }
  }

  depends_on = [aws_security_group.msk]
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.default.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.default.bootstrap_brokers_tls
}