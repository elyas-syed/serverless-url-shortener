import json
import time
from typing import Any

import boto3

from shared.config import get_env
from shared.responses import error_response, json_response, redirect_response

dynamodb = boto3.resource("dynamodb")
sqs = boto3.client("sqs")
links_table = dynamodb.Table(get_env("LINKS_TABLE_NAME"))


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    slug = (event.get("pathParameters") or {}).get("slug")
    if not slug:
        path = event.get("rawPath") or event.get("path", "")
        slug = path.strip("/")

    if slug == "health":
        return json_response(200, {"status": "ok"})

    if not slug:
        return error_response(404, "Not found.")

    response = links_table.get_item(Key={"slug": slug})
    item = response.get("Item")
    if not item or not item.get("is_active", True):
        return error_response(404, "Short link not found.")

    expires_at = int(item.get("expires_at", 0))
    if expires_at and expires_at <= int(time.time()):
        return error_response(410, "Short link has expired.")

    queue_url = get_env("CLICK_EVENTS_QUEUE_URL")
    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps({"slug": slug, "clicked_at": int(time.time())}),
    )

    return redirect_response(item["long_url"])
