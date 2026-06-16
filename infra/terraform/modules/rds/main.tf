locals {
  common_tags = merge(var.tags, {
    Module = "rds"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.name_prefix}-postgres17"
  family      = "postgres17"
  description = "PostgreSQL 17 parameters for ${var.name_prefix}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-postgres17"
  })
}

resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  parameter_group_name   = aws_db_parameter_group.postgres.name

  multi_az                  = var.multi_az
  publicly_accessible       = false
  deletion_protection       = var.deletion_protection
  backup_retention_period   = var.backup_retention_period
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.db_identifier}-final"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = var.monitoring_role_arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(local.common_tags, {
    Name = var.db_identifier
  })
}
