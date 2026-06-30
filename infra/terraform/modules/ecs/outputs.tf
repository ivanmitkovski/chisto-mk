output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "service_name" {
  value = aws_ecs_service.api.name
}

output "api_task_definition_family" {
  value = aws_ecs_task_definition.api.family
}

output "migrate_task_definition_family" {
  value = aws_ecs_task_definition.migrate.family
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.api.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.api.arn
}
