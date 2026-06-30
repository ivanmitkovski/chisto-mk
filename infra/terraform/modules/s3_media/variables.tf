variable "bucket_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "cors_allowed_origins" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
