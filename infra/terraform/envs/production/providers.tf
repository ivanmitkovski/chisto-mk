provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "chisto"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
