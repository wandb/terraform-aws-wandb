resource "aws_iam_role_policy_attachment" "node_cloudwatch" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "node_IMDSv2" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_IMDSv2.arn
}

resource "aws_iam_role_policy_attachment" "node_kms" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_kms.arn
}

resource "aws_iam_role_policy_attachment" "node_sqs" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_sqs.arn
}

resource "aws_iam_role_policy_attachment" "node_s3" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_s3.arn
}
