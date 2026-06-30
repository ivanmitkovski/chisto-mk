output "replication_group_id" {
  value = aws_elasticache_replication_group.main.id
}

output "primary_endpoint_address" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "primary_endpoint_port" {
  value = aws_elasticache_replication_group.main.port
}

output "auth_token" {
  value     = random_password.auth_token.result
  sensitive = true
}

output "redis_url_template" {
  value     = "rediss://:${random_password.auth_token.result}@${aws_elasticache_replication_group.main.primary_endpoint_address}:${aws_elasticache_replication_group.main.port}"
  sensitive = true
}
