locals {
  common_tags = {
    Environment = var.environment
  }

  container_image = "${module.ecr.repository_url}:${var.container_image_tag}"
}

module "network" {
  source = "../../modules/network"

  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

module "kms" {
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  tags        = local.common_tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix = var.name_prefix
  vpc_id      = module.network.vpc_id
  tags        = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
  tags            = local.common_tags
}

module "s3_media" {
  source = "../../modules/s3_media"

  bucket_name          = var.s3_bucket_name
  kms_key_arn          = module.kms.s3_key_arn
  cors_allowed_origins = var.s3_cors_allowed_origins
  tags                 = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  secret_name = var.secret_name
  kms_key_arn = module.kms.secrets_key_arn
  tags        = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix         = var.name_prefix
  aws_region          = var.aws_region
  github_repository   = var.github_repository
  github_branches     = var.github_branches
  secret_arn          = module.secrets.secret_arn
  secrets_kms_key_arn = module.kms.secrets_key_arn
  s3_bucket_arn       = module.s3_media.bucket_arn
  s3_kms_key_arn      = module.kms.s3_key_arn
  ecr_repository_arn  = module.ecr.repository_arn
  ecs_cluster_name    = var.ecs_cluster_name
  tags                = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix         = var.name_prefix
  db_identifier       = var.db_identifier
  instance_class      = var.db_instance_class
  subnet_ids          = module.network.private_subnet_ids
  security_group_ids  = [module.security_groups.rds_security_group_id]
  kms_key_arn         = module.kms.rds_key_arn
  monitoring_role_arn = module.iam.rds_monitoring_role_arn
  deletion_protection = var.rds_deletion_protection
  tags                = local.common_tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  name_prefix          = var.name_prefix
  replication_group_id = var.redis_replication_group_id
  node_type            = var.redis_node_type
  subnet_ids           = module.network.private_subnet_ids
  security_group_ids   = [module.security_groups.redis_security_group_id]
  tags                 = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix                           = var.name_prefix
  vpc_id                                = module.network.vpc_id
  public_subnet_ids                     = module.network.public_subnet_ids
  security_group_id                     = module.security_groups.alb_security_group_id
  certificate_domain_name               = var.api_domain
  certificate_subject_alternative_names = var.certificate_subject_alternative_names
  health_check_path                     = "/health/ready"
  tags                                  = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix             = var.name_prefix
  cluster_name            = var.ecs_cluster_name
  service_name            = var.ecs_service_name
  aws_region              = var.aws_region
  container_image         = local.container_image
  desired_count           = var.ecs_desired_count
  min_capacity            = var.ecs_desired_count == 0 ? 0 : var.ecs_min_capacity
  max_capacity            = var.ecs_max_capacity
  private_subnet_ids      = module.network.private_subnet_ids
  task_security_group_id  = module.security_groups.task_security_group_id
  target_group_arn        = module.alb.target_group_arn
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  execution_role_arn      = module.iam.ecs_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  secret_arn              = module.secrets.secret_arn
  logs_kms_key_arn        = module.kms.logs_key_arn
  log_retention_in_days   = var.log_retention_in_days
  s3_bucket_name          = module.s3_media.bucket_name
  vpc_cidr                = module.network.vpc_cidr
  api_domain              = var.api_domain
  share_base_url          = var.share_base_url
  admin_app_base_url      = var.admin_app_base_url
  cors_origins            = var.cors_origins
  chat_ws_cors_origins    = var.chat_ws_cors_origins
  tags                    = local.common_tags
}

module "waf" {
  source = "../../modules/waf"

  name_prefix = var.name_prefix
  alb_arn     = module.alb.alb_arn
  rate_limit  = var.waf_rate_limit
  tags        = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  name_prefix                = var.name_prefix
  alarm_email                = var.alarm_email
  alb_arn_suffix             = module.alb.alb_arn_suffix
  target_group_arn_suffix    = module.alb.target_group_arn_suffix
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_service_name           = module.ecs.service_name
  ecs_min_capacity           = var.ecs_min_capacity
  rds_instance_id            = module.rds.db_instance_id
  redis_replication_group_id = module.elasticache.replication_group_id
  tags                       = local.common_tags
}

module "rds_password_sync" {
  source = "../../modules/rds-password-sync"

  name_prefix           = var.name_prefix
  aws_region            = var.aws_region
  rds_secret_arn        = module.rds.master_user_secret_arn
  app_secret_arn        = module.secrets.secret_arn
  secrets_kms_key_arn   = module.kms.secrets_key_arn
  db_host               = module.rds.db_endpoint
  db_port               = module.rds.db_port
  db_name               = module.rds.db_name
  ecs_cluster_name      = module.ecs.cluster_name
  ecs_service_name      = module.ecs.service_name
  alarm_sns_topic_arn   = module.observability.sns_topic_arn
  log_retention_in_days = var.log_retention_in_days
  tags                  = local.common_tags
}
