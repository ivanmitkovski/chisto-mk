locals {
  common_tags = merge(var.tags, {
    Module = "secrets"
  })

  # Placeholder JSON keys only — values are populated out-of-band.
  placeholder_keys = {
    DATABASE_URL                  = "REPLACE_ME"
    JWT_SECRET                    = "REPLACE_ME"
    CHAT_ENCRYPTION_KEY           = "REPLACE_ME"
    CHECK_IN_QR_SECRET            = "REPLACE_ME"
    SITE_SHARE_TOKEN_SECRET       = "REPLACE_ME"
    METRICS_BEARER_TOKEN          = "REPLACE_ME"
    REDIS_URL                     = "REPLACE_ME"
    TWILIO_AUTH_TOKEN             = "REPLACE_ME"
    TWILIO_ACCOUNT_SID            = "REPLACE_ME"
    POSTMARK_SERVER_TOKEN         = "REPLACE_ME"
    POSTMARK_WEBHOOK_BASIC_PASS   = "REPLACE_ME"
    FIREBASE_SERVICE_ACCOUNT_JSON = "REPLACE_ME"
    TWILIO_MESSAGING_SERVICE_SID  = "REPLACE_ME"
  }
}

resource "aws_secretsmanager_secret" "api" {
  name       = var.secret_name
  kms_key_id = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = var.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "api" {
  secret_id     = aws_secretsmanager_secret.api.id
  secret_string = jsonencode(local.placeholder_keys)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
