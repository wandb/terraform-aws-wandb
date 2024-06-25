data "aws_caller_identity" "current" {}

resource "aws_iam_role" "irsa" {
  name = "${var.namespace}-yace-irsa-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = ""
        Effect    = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.aws_iam_openid_connect_provider_url}"
        }
        Action    = ["sts:AssumeRoleWithWebIdentity"]
        Condition = {
          StringLike = {
            "${var.aws_iam_openid_connect_provider_url}:sub" = "system:serviceaccount:default:${var.yace_sa_name}"
            "${var.aws_iam_openid_connect_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "irsa" {
  name        = "${var.namespace}-yace-irsa-policy"
  description = "IRSA IAM Policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "tag:GetResources",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.irsa.arn
}