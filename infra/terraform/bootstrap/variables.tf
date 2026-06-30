variable "aws_region" {
  type        = string
  description = "AWS region for the Terraform state bucket and lock table."
  default     = "eu-central-1"
}
