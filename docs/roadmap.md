# Roadmap

Planned improvements and known gaps. Items are ordered roughly by priority for moving from demo to production.

## In progress / stubbed

### API key authentication

- `auth_mode` variable exists (`open` | `api_key`)
- Lambdas read `AUTH_MODE`; delete is gated on mode
- **Missing:** API Gateway usage plan, API keys, and request authorizer or header validation on create

**Target:** Set `auth_mode = "api_key"` and have `POST /api/links` require `x-api-key`.

## Planned

### CI/CD (GitHub Actions)

- `make test` and `make validate` on pull requests
- Optional `terraform plan` with OIDC AWS role
- Automated Lambda build artifact caching

### AWS WAF (extended rules)

- AWS Managed Rules / common rule set for known bad inputs
- Budget impact: ~$5+/month base already applies when WAF is enabled — see [Cost](cost.md)

Basic rate-based WAF on CloudFront is **implemented** as an optional toggle (`enable_waf`, default `false`).

### Enhanced observability

- SNS topic for CloudWatch alarms
- Structured JSON logging in Lambdas
- Optional X-Ray tracing on API Gateway + Lambda

### Multi-environment support

- `dev` / `prod` workspaces or directory-based environments
- Separate state keys per environment
- Environment-specific tfvars (gitignored)

## Nice to have

- Link preview / Open Graph metadata endpoint
- QR code generation in web UI
- Admin dashboard for link management
- Custom slug namespaces per API key
- DynamoDB point-in-time recovery toggle for production

## Completed

- [x] Serverless architecture (Lambda, DynamoDB, SQS, API Gateway, CloudFront)
- [x] Terraform modular IaC
- [x] S3 native state lockfile bootstrap
- [x] Demo mode with per-IP rate limiting
- [x] Custom domain support (Route53 + ACM)
- [x] Async click tracking via SQS
- [x] Web UI with modern styling
- [x] Default link TTL (3 days)
- [x] Optional AWS WAF on CloudFront (rate-based rule, `enable_waf`)
- [x] Project documentation (`docs/`)

## Contributing

Pick an item, open an issue or PR, and reference this roadmap. See [Development](development.md) for the workflow.
