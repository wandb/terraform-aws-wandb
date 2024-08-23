data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:cluster-autoscaler:*"]
    }

    principals {
      identifiers = [var.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "default" {
  assume_role_policy = data.aws_iam_policy_document.default.json
  name               = "${var.namespace}-cluster-autoscaler"
}

resource "aws_iam_policy" "default" {
  policy = templatefile("NodeTerminationHandler.json", { namespace = var.namespace })
  name   = "${var.namespace}-cluster-autoscaler"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}