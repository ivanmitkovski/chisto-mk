output "rds_key_arn" {
  value = aws_kms_key.keys["rds"].arn
}

output "s3_key_arn" {
  value = aws_kms_key.keys["s3"].arn
}

output "secrets_key_arn" {
  value = aws_kms_key.keys["secrets"].arn
}

output "logs_key_arn" {
  value = aws_kms_key.keys["logs"].arn
}

output "key_arns" {
  value = { for k, v in aws_kms_key.keys : k => v.arn }
}
