resource "aws_elasticache_user" "juicefs" {
  user_id       = "juicefs"
  user_name     = "juicefs"
  access_string = "on ~* +@all -@dangerous"
  engine        = "REDIS"
  passwords = [
     random_password.juicefs.result
  ]
 
}

resource "random_password" "juicefs" {
  length      = 32
  lower       = true
  min_lower   = 8
  min_numeric = 8
  min_special = 0
  min_upper   = 8
  numeric     = true
  special     = false
  upper       = true
}