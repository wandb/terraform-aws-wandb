output "account_id" {
  value = aws_caller_identity.current.account_id
}

output "role" {
  value = aws_iam_role.access.name
}