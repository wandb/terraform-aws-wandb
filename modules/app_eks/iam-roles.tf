resource "aws_iam_role" "node" {
  name               = "${var.namespace}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  inline_policy {}

}

