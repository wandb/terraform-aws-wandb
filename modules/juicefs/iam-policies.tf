
resource "aws_iam_policy" "juicefs" {
  name   = "${var.namespace}-juicefs"
  policy = data.aws_iam_policy_document.juicefs.json
  lifecycle {
    create_before_destroy = false
  }

}
