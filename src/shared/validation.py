"""URL and slug validation."""

import ipaddress
import re
from urllib.parse import urlparse

RESERVED_SLUGS = {
    "api",
    "health",
    "admin",
    "links",
    "docs",
    "index.html",
    "favicon.ico",
    "static",
    "assets",
}

SLUG_PATTERN = re.compile(r"^[a-zA-Z0-9_-]{3,32}$")
MAX_URL_LENGTH = 2048


def validate_url(url: str) -> str | None:
    if not url or len(url) > MAX_URL_LENGTH:
        return "URL is required and must be at most 2048 characters."

    parsed = urlparse(url.strip())
    if parsed.scheme not in {"http", "https"}:
        return "URL must use http or https."

    if not parsed.netloc:
        return "URL must include a valid host."

    host = parsed.hostname
    if not host:
        return "URL must include a valid host."

    if host.lower() in {"localhost", "127.0.0.1", "0.0.0.0"}:
        return "URL host is not allowed."

    try:
        ip = ipaddress.ip_address(host)
        if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved:
            return "URL host is not allowed."
    except ValueError:
        pass

    return None


def validate_slug(slug: str) -> str | None:
    if not SLUG_PATTERN.match(slug):
        return "Slug must be 3-32 characters and use letters, numbers, _ or - only."

    if slug.lower() in RESERVED_SLUGS:
        return "Slug is reserved."

    return None


def generate_slug(length: int = 7) -> str:
    import secrets
    import string

    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))
