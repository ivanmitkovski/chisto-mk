variable "name_prefix" {
  type        = string
  description = "Resource name prefix, e.g. chisto-prod."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block."
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for public/private subnets."
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags."
  default     = {}
}
