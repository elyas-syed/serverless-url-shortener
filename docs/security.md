# Security

## Threat model (demo deployment)

The default configuration is designed for **portfolio demos and learning**, not open production use without additional controls.

| Risk | Mitigation (current) | Production gap |
|------|---------------------|----------------|
| Abuse of create API | Per-IP rate limiting (5/min) | API keys, optional WAF, account quotas |
| SSRF via destination URLs | URL validation blocks private/loopback IPs | Stricter allowlists if needed |
| Slug squatting | Reserved slug list | Auth required to create |
| Data deletion | DELETE disabled in open mode | API key auth for delete |
| DDoS | API Gateway throttling | Optional AWS WAF on CloudFront (`enable_waf`) |
| Data at rest | DynamoDB SSE, S3 SSE | — |
| Data in transit | HTTPS everywhere via CloudFront | — |

## Authentication modes

Controlled by `auth_mode` in `terraform.tfvars`:

### `open` (default)

- `POST /api/links` is public
- Rate limited per IP via DynamoDB (`src/shared/rate_limit.py`)
- `DELETE /api/links/{slug}` returns `403`
- Suitable for demos with low traffic

### `api_key` (partial)

- Terraform sets `AUTH_MODE=api_key` on Lambdas
- Delete endpoint enabled in Lambda logic
- API Gateway usage plan and key validation **not yet wired** — see [Roadmap](roadmap.md)

## Input validation

Implemented in `src/shared/validation.py`:

**URLs**

- Only `http`/`https` schemes
- Maximum 2048 characters
- Hostname required
- Blocked: `localhost`, loopback, link-local, private, and reserved IP ranges

**Slugs**

- 3–32 characters: letters, digits, `_`, `-`
- Reserved paths blocked to avoid collisions with CloudFront routes (`api`, `health`, `assets`, etc.)

## Rate limiting

Two layers enforce limits on create requests:

1. **Lambda + DynamoDB** — sliding 60-second window per `client_ip`
2. **API Gateway stage** — `throttling_rate_limit` and `throttling_burst_limit` match `rate_limit_per_minute`

Client IP resolution order:

1. `X-Forwarded-For` header (first address)
2. API Gateway `requestContext.http.sourceIp`

## IAM

A single Lambda execution role (`url-shortener-lambda`) with least-privilege inline policy:

- DynamoDB: `GetItem`, `PutItem`, `UpdateItem` on `links` and `rate_limits` tables
- SQS: `SendMessage` (redirect), `ReceiveMessage`/`DeleteMessage` (click_tracker)

No Lambdas have blanket `dynamodb:*` or `s3:*` permissions.

## Frontend bucket

- Public access blocked on the frontend S3 bucket
- Objects served only through CloudFront Origin Access Control (OAC)
- Bucket policy allows `s3:GetObject` only from the CloudFront distribution ARN

## State bucket

Bootstrap bucket configuration:

- Versioning enabled (required for lockfile)
- SSE-S3 encryption
- Public access blocked
- Globally unique name via `random_id` hex suffix (no account ID in repo)
- Bucket name kept in gitignored `backend.hcl`, not in tracked Terraform
- Noncurrent versions expire after 90 days
- Teardown via `make bootstrap-destroy` (enables `force_destroy`; run `make infra-destroy` on the app stack first)

## Optional controls (off by default)

| Control | How to enable | Why off by default |
|---------|---------------|-------------------|
| AWS WAF | `enable_waf = true` in `terraform.tfvars` | ~$5+/month minimum; overkill for demo traffic |

## What we skipped (and why)

| Control | Reason |
|---------|--------|
| Cognito / OAuth | Complexity; API keys sufficient for next tier |
| VPC / private subnets | Not needed for managed serverless APIs |
| Secrets Manager | No secrets in demo mode |

## Production hardening checklist

- [ ] Enable `auth_mode = "api_key"` with usage plans
- [ ] Set `enable_waf = true` for edge rate limiting on CloudFront (see [Cost](cost.md))
- [ ] Enable AWS CloudTrail and log aggregation
- [ ] Tighten CORS if exposing API to third-party browsers
- [ ] Review CloudWatch alarms and SNS notifications
- [ ] Consider per-tenant quotas beyond IP rate limits
