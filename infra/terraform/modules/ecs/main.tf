locals {
  common_tags = merge(var.tags, {
    Module = "ecs"
  })

  api_task_family     = "${var.name_prefix}-api"
  migrate_task_family = "${var.name_prefix}-api-migrate"
  log_group_name      = "/ecs/${local.api_task_family}"

  # Keys stored in Secrets Manager (populated out-of-band; placeholders at create time).
  secret_keys = [
    "DATABASE_URL",
    "JWT_SECRET",
    "CHAT_ENCRYPTION_KEY",
    "CHECK_IN_QR_SECRET",
    "SITE_SHARE_TOKEN_SECRET",
    "METRICS_BEARER_TOKEN",
    "REDIS_URL",
    "TWILIO_AUTH_TOKEN",
    "TWILIO_ACCOUNT_SID",
    "POSTMARK_SERVER_TOKEN",
    "POSTMARK_WEBHOOK_BASIC_PASS",
    "FIREBASE_SERVICE_ACCOUNT_JSON",
    "TWILIO_MESSAGING_SERVICE_SID",
  ]

  api_environment = [
    { name = "AWS_REGION", value = var.aws_region },
    { name = "PORT", value = "3000" },
    { name = "NODE_ENV", value = "production" },
    { name = "JWT_ACCESS_EXPIRES_IN", value = "900" },
    { name = "JWT_REFRESH_EXPIRES_DAYS", value = "90" },
    { name = "JWT_REFRESH_STANDARD_DAYS", value = "7" },
    { name = "REFRESH_TOKEN_ROTATION_GRACE_SECONDS", value = "120" },
    { name = "MAX_SESSIONS_PER_USER", value = "20" },
    { name = "CORS_ORIGINS", value = var.cors_origins },
    { name = "ADMIN_APP_BASE_URL", value = var.admin_app_base_url },
    { name = "SHARE_BASE_URL", value = var.share_base_url },
    { name = "SMS_PROVIDER", value = "twilio" },
    { name = "TWILIO_WEBHOOK_BASE_URL", value = "https://${var.api_domain}" },
    { name = "NOTIFICATIONS_INBOX_ENABLED", value = "true" },
    { name = "PUSH_FCM_ENABLED", value = "true" },
    { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
    { name = "EMAIL_ENABLED", value = "true" },
    { name = "EMAIL_FROM_NAME", value = "Chisto.mk" },
    { name = "EMAIL_PUBLIC_API_BASE_URL", value = "https://${var.api_domain}" },
    { name = "EMAIL_APP_BASE_URL", value = var.share_base_url },
    { name = "POSTMARK_WEBHOOK_BASIC_USER", value = "postmark-webhook" },
    { name = "GEOIP_ENABLED", value = "false" },
    { name = "MIGRATE_DEPLOY_ON_START", value = "0" },
    { name = "TRUSTED_PROXY_CIDRS", value = var.vpc_cidr },
  ]

  api_secrets = [
    for key in local.secret_keys : {
      name      = key
      valueFrom = "${var.secret_arn}:${key}::"
    }
  ]

  migrate_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = "${var.secret_arn}:DATABASE_URL::"
    }
  ]
}

resource "aws_cloudwatch_log_group" "api" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.logs_kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.log_group_name
  })
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = var.cluster_name
  })
}

resource "aws_ecs_task_definition" "api" {
  family                   = local.api_task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "chisto-api"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          appProtocol   = "http"
          name          = "chisto-api-3000-tcp"
        }
      ]
      environment = local.api_environment
      secrets     = local.api_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = local.api_task_family
  })
}

resource "aws_ecs_task_definition" "migrate" {
  family                   = local.migrate_task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name       = "chisto-api-migrate"
      image      = var.container_image
      essential  = true
      entryPoint = ["sh", "-c"]
      command    = ["cd /app && prisma generate && prisma migrate deploy"]
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "SKIP_MIGRATE_STATUS_CHECK", value = "1" },
      ]
      secrets = local.migrate_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "migrate"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = local.migrate_task_family
  })
}

resource "aws_ecs_service" "api" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 180

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.task_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "chisto-api"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = merge(local.common_tags, {
    Name = var.service_name
  })

  depends_on = [aws_ecs_task_definition.api]
}

resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.name_prefix}-api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "api_alb_requests" {
  name               = "${var.name_prefix}-api-alb-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${var.target_group_arn_suffix}"
    }
    target_value       = 1000
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}
