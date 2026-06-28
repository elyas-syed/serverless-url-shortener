import json
import time
from typing import Any

import boto3

from shared.config import auth_mode, get_env
from shared.responses import error_response, json_response


dynamodb = boto3.resource("dynamodb")
links_table = dynamodb.Table(get_env("LINKS_TABLE_NAME"))


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    slug = (event.get("pathParameters") or {}).get("slug")

    if not slug:
        return error_response(400, "Slug is required.")

    if method == "DELETE":
        if auth_mode() == "open":
            return error_response(403, "Delete is disabled in demo mode.")
        return _delete_link(slug)

    if method != "GET":
        return error_response(405, "Method not allowed.")

    response = links_table.get_item(Key={"slug": slug})
    item = response.get("Item")
    if not item:
        return error_response(404, "Short link not found.")

    expires_at = int(item.get("expires_at", 0))
    expired = expires_at and expires_at <= int(time.time())

    base_url = get_env("BASE_URL", "")
    short_url = f"{base_url.rstrip('/')}/{slug}" if base_url else f"/{slug}"

    return json_response(
        200,
        {
            "slug": slug,
            "long_url": item["long_url"],
            "short_url": short_url,
            "created_at": item.get("created_at"),
            "expires_at": expires_at,
            "click_count": int(item.get("click_count", 0)),
            "is_active": item.get("is_active", True),
            "expired": expired,
        },
    )


def _delete_link(slug: str) -> dict[str, Any]:
    try:
        links_table.update_item(
            Key={"slug": slug},
            UpdateExpression="SET is_active = :inactive",
            ConditionExpression="attribute_exists(slug)",
            ExpressionAttributeValues={":inactive": False},
        )
    except links_table.meta.client.exceptions.ConditionalCheckFailedException:
        return error_response(404, "Short link not found.")

    return json_response(200, {"slug": slug, "deleted": True})
