import json
import time
from typing import Any

import boto3

from shared.config import auth_mode, default_link_ttl_days, get_env, rate_limit_per_minute
from shared.rate_limit import RateLimiter
from shared.responses import error_response, json_response
from shared.validation import generate_slug, validate_slug, validate_url


dynamodb = boto3.resource("dynamodb")
links_table = dynamodb.Table(get_env("LINKS_TABLE_NAME"))


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    method = event.get("requestContext", {}).get("http", {}).get("method", "POST")
    if method != "POST":
        return error_response(405, "Method not allowed.")

    if auth_mode() == "open":
        limiter = RateLimiter(get_env("RATE_LIMITS_TABLE_NAME"), rate_limit_per_minute())
        client_ip = RateLimiter.client_ip_from_event(event)
        if not limiter.allow(client_ip):
            return error_response(429, "Rate limit exceeded. Try again in a minute.")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error_response(400, "Invalid JSON body.")

    long_url = body.get("url", "").strip()
    url_error = validate_url(long_url)
    if url_error:
        return error_response(400, url_error)

    slug = body.get("slug", "").strip()
    if slug:
        slug_error = validate_slug(slug)
        if slug_error:
            return error_response(400, slug_error)
    else:
        slug = generate_slug()

    expires_in_days = body.get("expires_in_days", default_link_ttl_days())
    try:
        expires_in_days = int(expires_in_days)
        if expires_in_days < 1 or expires_in_days > 365:
            raise ValueError
    except (TypeError, ValueError):
        return error_response(400, "expires_in_days must be between 1 and 365.")

    now = int(time.time())
    item = {
        "slug": slug,
        "long_url": long_url,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
        "expires_at": now + (expires_in_days * 86400),
        "click_count": 0,
        "is_active": True,
    }

    try:
        links_table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(slug)",
        )
    except links_table.meta.client.exceptions.ConditionalCheckFailedException:
        return error_response(409, "Slug already exists.")

    base_url = get_env("BASE_URL", "")
    short_url = f"{base_url.rstrip('/')}/{slug}" if base_url else f"/{slug}"

    return json_response(
        201,
        {
            "slug": slug,
            "long_url": long_url,
            "short_url": short_url,
            "expires_at": item["expires_at"],
            "click_count": 0,
        },
    )
