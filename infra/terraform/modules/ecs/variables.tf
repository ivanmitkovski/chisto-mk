variable "name_prefix" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "container_image" {
  type        = string
  description = "ECR image URI including tag, e.g. account.dkr.ecr.region.amazonaws.com/chisto-api:latest"
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 6
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "task_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for autoscaling metric, e.g. app/chisto-prod-alb/abc123."
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix for autoscaling metric, e.g. targetgroup/chisto-prod-tg/abc123."
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "secret_arn" {
  type = string
}

variable "logs_kms_key_arn" {
  type = string
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}

variable "s3_bucket_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "api_domain" {
  type = string
}

variable "share_base_url" {
  type = string
}

variable "admin_app_base_url" {
  type = string
}

variable "cors_origins" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
