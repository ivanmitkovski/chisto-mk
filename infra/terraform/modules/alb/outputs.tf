output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.api.arn_suffix
}

output "certificate_arn" {
  value = aws_acm_certificate.api.arn
}

output "certificate_domain_validation_options" {
  value = aws_acm_certificate.api.domain_validation_options
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}
