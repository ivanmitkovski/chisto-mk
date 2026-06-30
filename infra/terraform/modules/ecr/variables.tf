variable "repository_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "max_image_count" {
  type    = number
  default = 30
}
