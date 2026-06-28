"""Per-IP rate limiting backed by DynamoDB."""

import time
from typing import Any

import boto3


class RateLimiter:
    def __init__(self, table_name: str, limit_per_minute: int):
        self.table = boto3.resource("dynamodb").Table(table_name)
        self.limit = limit_per_minute
        self.window_seconds = 60

    def allow(self, client_ip: str) -> bool:
        now = int(time.time())
        window_start = now - (now % self.window_seconds)
        expires_at = window_start + self.window_seconds

        try:
            response = self.table.update_item(
                Key={"client_ip": client_ip},
                UpdateExpression="SET request_count = if_not_exists(request_count, :zero) + :one, window_start = :window_start, expires_at = :expires_at",
                ConditionExpression="attribute_not_exists(request_count) OR window_start <> :window_start OR request_count < :limit",
                ExpressionAttributeValues={
                    ":zero": 0,
                    ":one": 1,
                    ":window_start": window_start,
                    ":expires_at": expires_at,
                    ":limit": self.limit,
                },
                ReturnValues="UPDATED_NEW",
            )
            return True
        except self.table.meta.client.exceptions.ConditionalCheckFailedException:
            return False

    @staticmethod
    def client_ip_from_event(event: dict[str, Any]) -> str:
        headers = event.get("headers") or {}
        forwarded = headers.get("x-forwarded-for") or headers.get("X-Forwarded-For")
        if forwarded:
            return forwarded.split(",")[0].strip()
        request_context = event.get("requestContext", {})
        http = request_context.get("http", {})
        return http.get("sourceIp", "unknown")
