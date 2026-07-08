terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module = "rds-password-sync"
  })

  lambda_name = "${var.name_prefix}-rds-password-sync"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid = "ReadRdsManagedSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.rds_secret_arn]
  }

  statement {
    sid = "UpdateAppSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.app_secret_arn]
  }

  statement {
    sid = "DecryptSecretsKms"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [var.secrets_kms_key_arn]
  }

  statement {
    sid = "RedeployEcsService"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}",
    ]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(local.common_tags, {
    Name = "${local.lambda_name}-role"
  })
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.lambda_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(local.common_tags, {
    Name = "/aws/lambda/${local.lambda_name}"
  })
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${local.lambda_name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.common_tags, {
    Name = "${local.lambda_name}-dlq"
  })
}

resource "aws_lambda_function" "sync" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      RDS_SECRET_ARN = var.rds_secret_arn
      APP_SECRET_ID  = var.app_secret_arn
      DB_HOST        = var.db_host
      DB_PORT        = tostring(var.db_port)
      DB_NAME        = var.db_name
      ECS_CLUSTER    = var.ecs_cluster_name
      ECS_SERVICE    = var.ecs_service_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = merge(local.common_tags, {
    Name = local.lambda_name
  })
}

resource "aws_cloudwatch_event_rule" "rds_rotation" {
  name        = "${local.lambda_name}-rotation"
  description = "Trigger DATABASE_URL sync when RDS managed password rotation succeeds."

  event_pattern = jsonencode({
    source = ["aws.secretsmanager"]
    "detail-type" = [
      "AWS API Call via CloudTrail",
      "AWS Service Event via CloudTrail",
    ]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName   = ["RotationSucceeded"]
      additionalEventData = {
        SecretId = [var.rds_secret_arn]
      }
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.lambda_name}-rotation"
  })
}

resource "aws_cloudwatch_event_target" "rotation_lambda" {
  rule      = aws_cloudwatch_event_rule.rds_rotation.name
  target_id = "rds-password-sync"
  arn       = aws_lambda_function.sync.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }

  dead_letter_config {
    arn = aws_sqs_queue.dlq.arn
  }
}

resource "aws_lambda_permission" "rotation_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeRotation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_rotation.arn
}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.lambda_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json

  tags = merge(local.common_tags, {
    Name = "${local.lambda_name}-scheduler-role"
  })
}

data "aws_iam_policy_document" "scheduler_invoke" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.sync.arn]
  }
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  name   = "${local.lambda_name}-scheduler-invoke"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_invoke.json
}

resource "aws_scheduler_schedule" "reconcile" {
  name       = "${local.lambda_name}-reconcile"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.reconcile_schedule_expression

  target {
    arn      = aws_lambda_function.sync.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }

    dead_letter_config {
      arn = aws_sqs_queue.dlq.arn
    }

    input = jsonencode({
      source      = "aws.events"
      detail-type = "Scheduled Reconciliation"
    })
  }
}

resource "aws_lambda_permission" "scheduler" {
  statement_id  = "AllowExecutionFromEventBridgeScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.reconcile.arn
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.lambda_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "RDS password sync Lambda failed (rotation or reconciliation)."
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    FunctionName = aws_lambda_function.sync.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.lambda_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "RDS password sync dead-letter queue has messages."
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}
