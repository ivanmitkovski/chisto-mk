variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "rds_secret_arn" {
  type        = string
  description = "ARN of the RDS-managed master user password secret."
}

variable "app_secret_arn" {
  type        = string
  description = "ARN of the application secret containing DATABASE_URL."
}

variable "secrets_kms_key_arn" {
  type        = string
  description = "KMS key used to encrypt Secrets Manager secrets."
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic for Lambda failure alarms."
}

variable "reconcile_schedule_expression" {
  type        = string
  default     = "rate(15 minutes)"
  description = "EventBridge Scheduler expression for drift reconciliation."
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
