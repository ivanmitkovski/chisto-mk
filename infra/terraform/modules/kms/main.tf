data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aliases = {
    rds     = "alias/${var.name_prefix}/rds"
    s3      = "alias/${var.name_prefix}/s3"
    secrets = "alias/${var.name_prefix}/secrets"
    logs    = "alias/${var.name_prefix}/logs"
  }

  account_root = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

  common_tags = merge(var.tags, {
    Module = "kms"
  })
}

resource "aws_kms_key" "keys" {
  for_each = local.aliases

  description             = "Chisto ${each.key} encryption key (${var.name_prefix})"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-kms-${each.key}"
  })
}

resource "aws_kms_alias" "keys" {
  for_each = local.aliases

  name          = each.value
  target_key_id = aws_kms_key.keys[each.key].key_id
}

resource "aws_kms_key_policy" "logs" {
  key_id = aws_kms_key.keys["logs"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRoot"
        Effect    = "Allow"
        Principal = { AWS = local.account_root }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_key_policy" "rds" {
  key_id = aws_kms_key.keys["rds"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRoot"
        Effect    = "Allow"
        Principal = { AWS = local.account_root }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowRDS"
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key_policy" "secrets" {
  key_id = aws_kms_key.keys["secrets"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRoot"
        Effect    = "Allow"
        Principal = { AWS = local.account_root }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowSecretsManager"
        Effect    = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key_policy" "s3" {
  key_id = aws_kms_key.keys["s3"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRoot"
        Effect    = "Allow"
        Principal = { AWS = local.account_root }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
