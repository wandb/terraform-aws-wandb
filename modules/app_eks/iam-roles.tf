resource "aws_iam_role" "node" {
  name               = "${var.namespace}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  // todo: refactor --> v1.16.3
  inline_policy {}
}

