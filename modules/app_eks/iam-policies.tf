resource "aws_iam_policy" "node_cloudwatch_policy" {
  name   = "${var.namespace}-node-cloudwatch"
  policy = data.aws_iam_policy_document.node_cloudwatch_policy.json
}

resource "aws_iam_policy" "node_IMDSv2_policy" {
  name   = "${var.namespace}-node-IMDSv2"
  policy = data.aws_iam_policy_document.node_IMDSv2_policy.json
}

resource "aws_iam_policy" "node_kms_policy" {
  name   = "${var.namespace}-node-kms"
  policy = data.aws_iam_policy_document.node_kms_policy.json
}

resource "aws_iam_policy" "node_sqs_policy" {
  name   = "${var.namespace}-node-sqs"
  policy = data.aws_iam_policy_document.node_sqs_policy.json
}

resource "aws_iam_policy" "node_s3_policy" {
  name   = "${var.namespace}-node-s3"
  policy = data.aws_iam_policy_document.node_s3_policy.json
}