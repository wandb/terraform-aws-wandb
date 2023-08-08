resource "aws_iam_access_key" "juicefs" {
  user = aws_iam_user.juicefs.name
}

resource "aws_iam_user" "juicefs" {
  name          = "${var.namespace}-juicefs-metadatastore"
  path          = "/system/"
  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "juicefs" {
  user       = aws_iam_user.juicefs.id
  policy_arn = aws_iam_policy.juicefs.arn
}