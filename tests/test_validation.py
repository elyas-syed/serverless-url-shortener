import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "create_link"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from shared.validation import RESERVED_SLUGS, validate_slug, validate_url


def test_validate_url_accepts_https():
    assert validate_url("https://example.com/path") is None


def test_validate_url_rejects_javascript():
    assert validate_url("javascript:alert(1)") is not None


def test_validate_url_rejects_localhost():
    assert validate_url("http://localhost:8080") is not None


def test_validate_slug_accepts_simple_slug():
    assert validate_slug("demo-link_1") is None


def test_validate_slug_rejects_reserved():
    assert validate_slug("api") is not None
    assert "api" in RESERVED_SLUGS


def test_validate_slug_rejects_short_value():
    assert validate_slug("ab") is not None
