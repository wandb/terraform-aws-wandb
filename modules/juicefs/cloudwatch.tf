resource "aws_cloudwatch_log_group" "juicefs" {
  name = "juicefs"

  tags = {
    Environment = "production"
    Application = "juicefs"
  }
}
