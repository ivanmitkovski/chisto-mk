variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "certificate_domain_name" {
  type = string
}

variable "certificate_subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "idle_timeout" {
  type    = number
  default = 120
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}
