resource "random_pet" "efs" {
  length = 2
}

resource "aws_efs_file_system" "storage_class" {
  creation_token   = "${var.namespace}-${random_pet.efs.id}"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"


  tags = {
    Name = "${var.namespace}-efs-${random_pet.efs.id}"
  }
}

resource "aws_efs_backup_policy" "storage_class" {
  file_system_id = aws_efs_file_system.storage_class.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_security_group" "storage_class_nfs" {
  name        = "nfs-security-group"
  description = "Security group for NFS traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS inbound"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.primary_workers_security_group_id]
  }

  tags = {
    Name = "nfs-security-group"
  }
}


resource "aws_efs_mount_target" "storage_class" {
  for_each        = { for subnet in var.private_subnets : subnet => subnet }
  file_system_id  = aws_efs_file_system.storage_class.id
  subnet_id       = each.value
  security_groups = [aws_security_group.storage_class_nfs.id]
}
