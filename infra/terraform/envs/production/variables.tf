variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "name_prefix" {
  type    = string
  default = "chisto-prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "api_domain" {
  type    = string
  default = "api.chisto.mk"
}

variable "certificate_subject_alternative_names" {
  type    = list(string)
  default = ["chisto.mk"]
}

variable "share_base_url" {
  type    = string
  default = "https://chisto.mk"
}

variable "admin_app_base_url" {
  type    = string
  default = "https://admin.chisto.mk"
}

variable "cors_origins" {
  type    = string
  default = "https://admin.chisto.mk"
}

variable "chat_ws_cors_origins" {
  type        = string
  default     = "https://admin.chisto.mk,https://chisto.mk"
  description = "Socket.IO CORS allowlist (comma-separated). Native mobile clients omit Origin; browser/admin clients need explicit entries."
}

variable "s3_bucket_name" {
  type    = string
  default = "chisto-prod-media"
}

variable "s3_cors_allowed_origins" {
  type = list(string)
  default = [
    "https://chisto.mk",
    "https://admin.chisto.mk",
  ]
}

variable "ecr_repository_name" {
  type    = string
  default = "chisto-api"
}

variable "secret_name" {
  type    = string
  default = "chisto/production/api"
}

variable "db_identifier" {
  type    = string
  default = "chisto-prod"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "redis_replication_group_id" {
  type    = string
  default = "chisto-prod-redis"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "ecs_cluster_name" {
  type    = string
  default = "chisto-prod"
}

variable "ecs_service_name" {
  type    = string
  default = "chisto-api"
}

variable "ecs_desired_count" {
  type        = number
  default     = 2
  description = "Set to 0 for initial infra apply before the first ECR image push."
}

variable "ecs_min_capacity" {
  type    = number
  default = 2
}

variable "ecs_max_capacity" {
  type    = number
  default = 6
}

variable "github_repository" {
  type    = string
  default = "ivanmitkovski/chisto-mk"
}

variable "github_branches" {
  type    = list(string)
  default = ["main", "develop"]
}

variable "alarm_email" {
  type        = string
  description = "Email for CloudWatch alarm notifications (requires SNS confirmation)."
}

variable "container_image_tag" {
  type        = string
  default     = "latest"
  description = "ECR image tag for the API container."
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}
