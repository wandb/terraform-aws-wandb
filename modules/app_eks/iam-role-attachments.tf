resource "aws_iam_role_policy_attachment" "node_cloudwatch" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_IMDSv2_policy" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_IMDSv2_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_kms_policy" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_sqs_policy" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_s3_policy" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node_s3_policy.arn
}
