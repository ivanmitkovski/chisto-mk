variable "secret_name" {
  type        = string
  description = "Secrets Manager secret name, e.g. chisto/production/api."
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
