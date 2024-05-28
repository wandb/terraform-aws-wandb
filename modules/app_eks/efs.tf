resource "random_pet" "efs" {
  length = 2
}

resource "aws_efs_file_system" "storage_class" {
  creation_token   = "${var.namespace}-${random_pet.efs.id}"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
}

resource "aws_efs_backup_policy" "storage_class" {
  file_system_id = aws_efs_file_system.storage_class.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_security_group" "storage_class_nfs" {
  name        = "${var.namespace}-${random_pet.efs.id}"
  description = "Security group for NFS traffic"
  vpc_id      = var.network_id
}

resource "aws_security_group_rule" "nfs_ingress" {
  description              = "NFS inbound"
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.storage_class_nfs.id
  source_security_group_id = aws_security_group.primary_workers.id
}

resource "aws_efs_mount_target" "storage_class" {
  for_each = { for index, subnet in var.network_private_subnets : index => subnet }

  file_system_id  = aws_efs_file_system.storage_class.id
  subnet_id       = each.value
  security_groups = [aws_security_group.storage_class_nfs.id]
}
