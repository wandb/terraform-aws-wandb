resource "aws_security_group" "msk_brokers_sg" {
  name        = "msk-brokers-sg"
  vpc_id      = data.aws_vpc.existing_vpc.id
  description = "Security group for MSK brokers"

  # Restrict inbound traffic to only necessary ports from your VPC CIDR
  ingress {
    from_port   = 2181 # Zookeeper
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing_vpc.cidr_block] 
  }

  # Add more ingress rules as needed for monitoring, etc.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "msk-brokers-sg"
  }
}

resource "aws_msk_cluster" "default" {
  cluster_name                   = "${var.namespace}"
  kafka_version          = "3.4.0" # Choose your desired Kafka version
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type    = "kafka.m5.large"  # Adjust instance type as needed
    client_subnets   = data.aws_subnets.private_subnets.ids
    security_groups  = [aws_security_group.msk_brokers_sg.id]
    # ebs_volume_size  = 50 # In GB
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS" 
    }
  }

  depends_on = [aws_security_group.msk_brokers_sg] 
}