# API reference

All endpoints are served through CloudFront at your `app_url` (custom domain or CloudFront default domain).

Base URL example: `https://your-domain.example`

## Endpoints

| Method | Path | Lambda | Description |
|--------|------|--------|-------------|
| `POST` | `/api/links` | `create_link` | Create a short link |
| `GET` | `/api/links/{slug}` | `get_analytics` | Get link metadata |
| `DELETE` | `/api/links/{slug}` | `get_analytics` | Soft-delete a link |
| `GET` | `/{slug}` | `redirect` | Redirect to long URL |
| `HEAD` | `/{slug}` | `redirect` | Redirect headers only |
| `GET` | `/health` | `redirect` | Health check |

## Create link

**`POST /api/links`**

### Request body

```json
{
  "url": "https://example.com/long/path",
  "slug": "my-link",
  "expires_in_days": 3
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `url` | Yes | Destination URL (`http` or `https`, max 2048 chars) |
| `slug` | No | Custom slug; auto-generated if omitted |
| `expires_in_days` | No | 1–365; defaults to `default_link_ttl_days` (3) |

### Success response `201`

```json
{
  "slug": "my-link",
  "long_url": "https://example.com/long/path",
  "short_url": "https://your-domain.example/my-link",
  "expires_at": 1719590400,
  "click_count": 0
}
```

### Error responses

| Status | Condition |
|--------|-----------|
| `400` | Invalid JSON, URL, slug, or `expires_in_days` |
| `409` | Slug already exists |
| `429` | Rate limit exceeded (`auth_mode = "open"`) |
| `405` | Non-POST method |

### Example

```bash
curl -X POST "$APP_URL/api/links" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","slug":"demo"}'
```

## Get link metadata

**`GET /api/links/{slug}`**

### Success response `200`

```json
{
  "slug": "demo",
  "long_url": "https://example.com",
  "short_url": "https://your-domain.example/demo",
  "created_at": "2026-06-28T08:00:00Z",
  "expires_at": 1719590400,
  "click_count": 42,
  "is_active": true,
  "expired": false
}
```

### Error responses

| Status | Condition |
|--------|-----------|
| `400` | Missing slug |
| `404` | Link not found |
| `405` | Unsupported method |

## Delete link

**`DELETE /api/links/{slug}`**

Soft-deletes by setting `is_active = false`.

| Status | Condition |
|--------|-----------|
| `200` | Link deactivated |
| `403` | Disabled when `auth_mode = "open"` (demo mode) |
| `404` | Link not found |

## Redirect

**`GET /{slug}`** or **`HEAD /{slug}`**

Returns `302` with `Location` header set to the long URL. Enqueues a click event asynchronously.

| Status | Condition |
|--------|-----------|
| `302` | Valid, active, non-expired link |
| `404` | Slug not found or inactive |
| `410` | Link expired |

### Example

```bash
curl -I "$APP_URL/demo"
```

## Health check

**`GET /health`**

```json
{"status": "ok"}
```

## Validation rules

### URL

- Scheme must be `http` or `https`
- Host required; max length 2048
- Blocked hosts: `localhost`, `127.0.0.1`, `0.0.0.0`, private/reserved IPs (SSRF protection)

### Slug

- Pattern: `^[a-zA-Z0-9_-]{3,32}$`
- Reserved slugs: `api`, `health`, `admin`, `links`, `docs`, `index.html`, `favicon.ico`, `static`, `assets`

## Rate limiting

In `auth_mode = "open"`:

- **Application layer:** 5 create requests per IP per minute (configurable via `rate_limit_per_minute`)
- **API Gateway stage:** Matching throttle rate and burst limit

Rate limit key is the client IP from `X-Forwarded-For` (first hop) or API Gateway `sourceIp`.

## API key auth (planned)

Setting `auth_mode = "api_key"` in Terraform updates Lambda environment variables. Full API Gateway usage plan and key validation wiring is planned — see [Roadmap](roadmap.md).

When implemented, clients will send:

```
x-api-key: <your-api-key>
```
