resource "aws_elasticache_user" "juicefs" {
  user_id       = "juicefs"
  user_name     = var.elasticache_user
  access_string = "on ~* +@all -@dangerous"
  engine        = "REDIS"
  authentication_mode {
    type = "password"
    passwords = [  "${var.elasticache_password}" ]
  } 
}
