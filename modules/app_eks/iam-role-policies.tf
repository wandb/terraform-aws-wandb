
data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    sid     = "aa1"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

