resource "random_password" "auth_token" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-redis-subnet-group"
    Module = "elasticache"
  })
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = var.replication_group_id
  description          = "Redis for ${var.name_prefix} API"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = var.security_group_ids

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(var.tags, {
    Name   = var.replication_group_id
    Module = "elasticache"
  })
}
