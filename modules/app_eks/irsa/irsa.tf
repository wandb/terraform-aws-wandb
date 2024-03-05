# Define the IAM role for IRSA
module "iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = var.policy_name
  path        = var.path
  description = "IRSA IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}

module "iam_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = var.role_name

  role_policy_arns = {
    policy = module.iam_policy.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = var.oidc_provider.arn
      namespace_service_accounts = ["${var.namespace}/*"]
    }
  }
}
