import json
from typing import Any

import boto3

from shared.config import get_env


dynamodb = boto3.resource("dynamodb")
links_table = dynamodb.Table(get_env("LINKS_TABLE_NAME"))


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    for record in event.get("Records", []):
        body = json.loads(record["body"])
        slug = body["slug"]
        links_table.update_item(
            Key={"slug": slug},
            UpdateExpression="ADD click_count :one",
            ExpressionAttributeValues={":one": 1},
            ConditionExpression="attribute_exists(slug)",
        )

    return {"batchItemFailures": []}
