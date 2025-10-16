data "aws_caller_identity" "current" {}

# IAM Policy Document for CSI Driver to access AWS Secrets Manager
data "aws_iam_policy_document" "secrets_manager_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${var.namespace}-*"]
  }
}

# IAM Policy for Secrets Store CSI Driver
resource "aws_iam_policy" "default" {
  name   = "${var.namespace}-secrets-store-csi-driver"
  policy = data.aws_iam_policy_document.secrets_manager_access.json
}

# IAM Assume Role Policy Document for IRSA
# Allow service accounts in the application namespace to assume this role
data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [var.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

# IAM Role for Secrets Store CSI Driver
resource "aws_iam_role" "default" {
  name               = "${var.namespace}-secrets-store-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = aws_iam_policy.default.arn
  role       = aws_iam_role.default.name
}

# Output the IAM role ARN for service account annotation
output "iam_role_arn" {
  value       = aws_iam_role.default.arn
  description = "ARN of the IAM role for service accounts to access AWS Secrets Manager"
}

# Output the IAM role trust policy for verification
output "iam_role_trust_policy" {
  value       = aws_iam_role.default.assume_role_policy
  description = "Trust policy (assume role policy) for the IAM role - shows which service accounts can assume this role"
}

# Output the IAM permissions policy for verification
output "iam_role_permissions_policy" {
  value       = data.aws_iam_policy_document.secrets_manager_access.json
  description = "Permissions policy for the IAM role - shows which secrets can be accessed"
}
