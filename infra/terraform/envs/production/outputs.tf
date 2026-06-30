output "vpc_id" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "api_domain" {
  value = var.api_domain
}

output "acm_certificate_validation_records" {
  description = "Add these CNAME records at your external DNS provider, then wait for certificate ISSUED."
  value = {
    for dvo in module.alb.certificate_domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "dns_records_required" {
  description = "Manual DNS records at your external registrar."
  value = {
    api_cname = {
      name  = var.api_domain
      type  = "CNAME"
      value = module.alb.alb_dns_name
    }
  }
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

output "rds_database_name" {
  value = module.rds.db_name
}

output "rds_master_user_secret_arn" {
  description = "AWS-managed secret for RDS master credentials. Build DATABASE_URL from this + endpoint."
  value       = module.rds.master_user_secret_arn
}

output "redis_primary_endpoint" {
  value = module.elasticache.primary_endpoint_address
}

output "redis_url" {
  description = "Set REDIS_URL in Secrets Manager (sensitive)."
  value       = module.elasticache.redis_url_template
  sensitive   = true
}

output "secrets_manager_secret_name" {
  value = module.secrets.secret_name
}

output "s3_bucket_name" {
  value = module.s3_media.bucket_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_actions_configuration" {
  description = "Repository secrets/variables for .github/workflows/api-deploy.yml"
  value = {
    AWS_ROLE_ARN                 = module.iam.github_deploy_role_arn
    ECS_CLUSTER                  = module.ecs.cluster_name
    ECS_SERVICE                  = module.ecs.service_name
    ECS_MIGRATE_TASK_DEFINITION  = module.ecs.migrate_task_definition_family
    ECS_SUBNETS                  = join(",", module.network.private_subnet_ids)
    ECS_SECURITY_GROUP           = module.security_groups.task_security_group_id
    AWS_REGION                   = var.aws_region
    ECR_REPOSITORY               = module.ecr.repository_name
    API_AWS_DEPLOY_repo_variable = "true"
  }
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "github_deploy_role_arn" {
  value = module.iam.github_deploy_role_arn
}

output "cloudwatch_dashboard_name" {
  value = module.observability.dashboard_name
}

output "sns_alarm_topic_arn" {
  value = module.observability.sns_topic_arn
}
