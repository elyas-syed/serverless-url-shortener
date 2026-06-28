"""Shared HTTP response helpers."""

import json
from typing import Any


def json_response(status_code: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }


def redirect_response(location: str, status_code: int = 302) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {
            "Location": location,
            "Cache-Control": "public, max-age=60",
        },
        "body": "",
    }


def error_response(status_code: int, message: str) -> dict[str, Any]:
    return json_response(status_code, {"error": message})
