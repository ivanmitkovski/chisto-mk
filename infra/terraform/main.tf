terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  type        = string
  description = "awsDev | staging | production"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

provider "aws" {
  region = var.aws_region
}

# --- Networking (scaffold) ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "chisto-${var.environment}" }
}

# --- RDS Postgres + PostGIS (scaffold; enable in follow-up apply) ---
# resource "aws_db_subnet_group" "api" { ... }
# resource "aws_rds_cluster" "api" { engine = "aurora-postgresql", ... }

# --- ElastiCache Redis (throttler, idempotency, Socket.IO) ---
# resource "aws_elasticache_cluster" "api" { ... }

# --- ECS Fargate API service ---
# resource "aws_ecs_cluster" "api" { name = "chisto-${var.environment}" }
# resource "aws_ecs_service" "api" { ... }

# --- ALB ---
# resource "aws_lb" "api" { ... }

# --- Secrets Manager references (no secret values in TF state) ---
# data "aws_secretsmanager_secret" "api_env" { name = "chisto/${var.environment}/api" }

output "environment" {
  value = var.environment
}

output "vpc_id" {
  value = aws_vpc.main.id
}
