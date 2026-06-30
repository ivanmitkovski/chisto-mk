variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/name format."
}

variable "github_branches" {
  type        = list(string)
  description = "Branches allowed to assume the deploy role."
  default     = ["main", "develop"]
}

variable "secret_arn" {
  type = string
}

variable "secrets_kms_key_arn" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "s3_kms_key_arn" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
