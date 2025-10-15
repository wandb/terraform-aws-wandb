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
data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:secrets-store-csi-driver"]
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
