"""Sync DATABASE_URL after RDS managed password rotation and redeploy ECS."""

from __future__ import annotations

import json
import logging
import os
import urllib.parse

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets = boto3.client("secretsmanager")
ecs = boto3.client("ecs")


def _trigger_label(event: dict) -> str:
    detail_type = event.get("detail-type")
    if detail_type:
        return detail_type
    if event.get("source") == "aws.events":
        return "scheduled-reconcile"
    return event.get("source", "manual")


def handler(event, context):
    rds_secret_arn = os.environ["RDS_SECRET_ARN"]
    app_secret_id = os.environ["APP_SECRET_ID"]
    db_host = os.environ["DB_HOST"]
    db_port = os.environ["DB_PORT"]
    db_name = os.environ["DB_NAME"]
    ecs_cluster = os.environ["ECS_CLUSTER"]
    ecs_service = os.environ["ECS_SERVICE"]
    trigger = _trigger_label(event)

    rds = json.loads(
        secrets.get_secret_value(
            SecretId=rds_secret_arn,
            VersionStage="AWSCURRENT",
        )["SecretString"]
    )
    app = json.loads(
        secrets.get_secret_value(SecretId=app_secret_id)["SecretString"]
    )

    current_url = app.get("DATABASE_URL", "")
    parsed = urllib.parse.urlparse(current_url)
    current_pass = urllib.parse.unquote(parsed.password) if parsed.password else ""
    rds_pass = rds["password"]
    rds_user = rds["username"]

    if (
        current_pass == rds_pass
        and parsed.username == rds_user
        and parsed.hostname == db_host
    ):
        logger.info("DATABASE_URL already in sync (trigger=%s)", trigger)
        return {"status": "in_sync", "trigger": trigger}

    encoded_password = urllib.parse.quote(rds_pass, safe="")
    app["DATABASE_URL"] = (
        f"postgresql://{rds_user}:{encoded_password}@{db_host}:{db_port}/{db_name}?sslmode=require"
    )

    secrets.put_secret_value(SecretId=app_secret_id, SecretString=json.dumps(app))
    logger.info("Updated DATABASE_URL in app secret (trigger=%s)", trigger)

    ecs.update_service(
        cluster=ecs_cluster,
        service=ecs_service,
        forceNewDeployment=True,
    )
    logger.info(
        "Triggered ECS force-new-deployment on %s/%s (trigger=%s)",
        ecs_cluster,
        ecs_service,
        trigger,
    )

    return {"status": "synced_and_redeployed", "trigger": trigger}
