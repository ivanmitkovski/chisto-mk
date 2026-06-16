variable "name_prefix" {
  type = string
}

variable "db_identifier" {
  type = string
}

variable "db_name" {
  type    = string
  default = "chisto_prod"
}

variable "db_username" {
  type    = string
  default = "chisto"
}

variable "engine_version" {
  type    = string
  default = "17.9"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "backup_retention_period" {
  type    = number
  default = 30
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "monitoring_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
