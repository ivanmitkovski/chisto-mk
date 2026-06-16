output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "task_security_group_id" {
  value = aws_security_group.task.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}
