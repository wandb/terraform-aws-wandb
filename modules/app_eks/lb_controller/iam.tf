data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [var.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "default" {
  assume_role_policy = data.aws_iam_policy_document.default.json
  name               = "${var.namespace}-aws-lb-controller"
}

resource "aws_iam_policy" "default" {
  policy = file("${path.module}/AWSLoadBalancerController.json")
  name   = "${var.namespace}-AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}
