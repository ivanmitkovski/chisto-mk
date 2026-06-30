variable "name_prefix" {
  type = string
}

variable "alarm_email" {
  type        = string
  description = "Email address for CloudWatch alarm notifications."
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "redis_replication_group_id" {
  type = string
}

variable "ecs_min_capacity" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
