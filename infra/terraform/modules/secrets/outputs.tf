output "secret_arn" {
  value = aws_secretsmanager_secret.api.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.api.name
}

output "secret_key_names" {
  value = keys(jsondecode(aws_secretsmanager_secret_version.api.secret_string))
}
