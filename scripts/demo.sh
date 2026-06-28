#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-}"

if [[ -z "$BASE_URL" ]]; then
  echo "Usage: $0 https://your-cloudfront-domain"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
SLUG="demo-$(date +%s)"

echo "Creating link..."
CREATE=$(curl -s -X POST "$BASE_URL/api/links" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"https://example.com\",\"slug\":\"$SLUG\"}")
echo "$CREATE"

echo "Checking redirect..."
curl -s -I "$BASE_URL/$SLUG" | head -n 1

echo "Checking stats..."
curl -s "$BASE_URL/api/links/$SLUG"

echo "Demo complete."
