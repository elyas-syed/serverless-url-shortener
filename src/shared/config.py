"""Environment configuration helpers."""

import os


def get_env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def auth_mode() -> str:
    return os.environ.get("AUTH_MODE", "open")


def rate_limit_per_minute() -> int:
    return int(os.environ.get("RATE_LIMIT_PER_MINUTE", "5"))


def default_link_ttl_days() -> int:
    return int(os.environ.get("DEFAULT_LINK_TTL_DAYS", "7"))
