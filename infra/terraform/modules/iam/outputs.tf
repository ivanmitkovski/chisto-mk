output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "ecs_execution_role_name" {
  value = aws_iam_role.ecs_execution.name
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  value = aws_iam_role.ecs_task.name
}

output "rds_monitoring_role_arn" {
  value = aws_iam_role.rds_monitoring.arn
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
