output "lambda_function_name" {
  value = aws_lambda_function.sync.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.sync.arn
}

output "rotation_event_rule_arn" {
  value = aws_cloudwatch_event_rule.rds_rotation.arn
}

output "reconcile_schedule_arn" {
  value = aws_scheduler_schedule.reconcile.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
