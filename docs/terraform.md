# Terraform

## Layout

```
terraform/
├── main.tf              # Root module wiring
├── variables.tf         # Input variables
├── outputs.tf           # Stack outputs
├── versions.tf          # Providers and backend config
├── terraform.tfvars     # Local values (gitignored)
├── bootstrap/           # Separate state bucket stack
└── modules/
    ├── api_gateway/
    ├── cloudfront/
    ├── dynamodb/
    ├── frontend/
    ├── lambda/
    ├── sqs/
    └── waf/
```

## Module dependency graph

```
dynamodb ──┐
sqs ───────┼──► lambda ──► api_gateway
           │                  │
           │                  ▼
frontend ──┴────────────► cloudfront ──► waf (optional)
```

## Modules

### `dynamodb`

- `links` table — hash key `slug`, TTL on `expires_at`, on-demand billing
- `rate_limits` table — hash key `client_ip`, TTL on `expires_at`

### `sqs`

- `click_events` queue with DLQ (max 3 receives)
- 4-day message retention on main queue

### `lambda`

Four functions sharing one IAM role:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `create_link` | API Gateway | Create short links |
| `redirect` | API Gateway | Redirect + health |
| `get_analytics` | API Gateway | Metadata + delete |
| `click_tracker` | SQS | Increment click counts |

Environment variables (`local.common_env`):

- `LINKS_TABLE_NAME`, `RATE_LIMITS_TABLE_NAME`, `CLICK_EVENTS_QUEUE_URL`
- `AUTH_MODE`, `RATE_LIMIT_PER_MINUTE`, `DEFAULT_LINK_TTL_DAYS`, `BASE_URL`

Zip paths and hashes are computed in root `main.tf` from `../dist/{function}.zip`.

### `api_gateway`

HTTP API (v2) with routes:

- `POST /api/links`
- `GET|DELETE /api/links/{slug}`
- `GET|HEAD /{slug}`
- `GET /health`

Default stage auto-deploys with throttling from `rate_limit_per_minute`.

### `frontend`

- S3 bucket for `web/` static files
- Uploads `index.html` and `assets/*` with content-based etag

### `cloudfront`

- Dual origins: S3 (frontend) and API Gateway (custom origin)
- Path-based cache behaviors (see [Architecture](architecture.md))
- Optional ACM cert + Route53 alias for custom domain

### `waf`

- Optional Web ACL scoped to CloudFront (`enable_waf`, default `false`)
- Rate-based rule blocks IPs exceeding `waf_rate_limit` requests per 5 minutes
- Associated with the CloudFront distribution via `aws_wafv2_web_acl_association`
- Deployed in `us-east-1` (required for CloudFront-scoped WAF)

## Root variables

| Variable | Passed to | Effect |
|----------|-----------|--------|
| `project_name` | All modules | Resource naming prefix |
| `auth_mode` | Lambda | `AUTH_MODE` env var |
| `rate_limit_per_minute` | Lambda, API Gateway | Rate limits |
| `default_link_ttl_days` | Lambda | Default expiration |
| `domain_name` | CloudFront, Lambda `BASE_URL` | Custom domain |
| `hosted_zone_id` | CloudFront | DNS records |
| `enable_waf` | WAF | Attach Web ACL to CloudFront |
| `waf_rate_limit` | WAF | Per-IP rate limit (5-minute window) |
| `tags` | All modules | Resource tags |

## Bootstrap vs root stack

| Stack | State | Purpose |
|-------|-------|---------|
| `terraform/bootstrap/` | Local or separate backend | S3 state bucket only |
| `terraform/` | S3 backend (after bootstrap) | Application infrastructure |

Never mix bootstrap resources into the root module — chicken-and-egg with the state bucket.

## Adding a new Lambda

1. Create `src/my_function/handler.py`
2. Add function name to `local.lambda_functions` in `terraform/main.tf`
3. Add Lambda resource in `terraform/modules/lambda/main.tf`
4. Wire API Gateway route and `aws_lambda_permission` if HTTP-triggered
5. Extend IAM policy in `lambda_permissions` if new AWS APIs are needed
6. Run `make build && terraform apply`

## Naming conventions

Resources follow `{project_name}-{purpose}`:

- `url-shortener-create-link` (Lambda)
- `url-shortener-links` (DynamoDB)
- `url-shortener-api` (API Gateway)

Tags default to `Project = url-shortener`, `Managed = terraform`.

## Outputs

| Output | Description |
|--------|-------------|
| `app_url` | Public shortener URL |
| `api_endpoint` | Raw API Gateway URL |
| `cloudfront_domain_name` | CloudFront distribution domain |
| `waf_enabled` | Whether WAF is attached (`enable_waf`) |
| `waf_web_acl_arn` | WAF Web ACL ARN (null when disabled) |
| `links_table_name` | DynamoDB links table |
| `rate_limits_table_name` | DynamoDB rate limits table |
| `click_events_queue_url` | SQS queue URL |
