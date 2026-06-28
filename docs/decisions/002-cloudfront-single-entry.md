# ADR 002: CloudFront as single public entry point

## Status

Accepted

## Context

The application serves both a static web UI and a dynamic API (create links, redirects, analytics). Options included:

1. Separate CloudFront distributions for S3 and API Gateway
2. Direct API Gateway URL for API, CloudFront for static only
3. Single CloudFront distribution with multiple origins and path-based behaviors

## Decision

Use one CloudFront distribution with two origins:

- **S3** — landing page, `index.html`, `/assets/*`
- **API Gateway** — `/api/*`, `/health`, and `/*` (short-link redirects)

Custom domain (optional) attaches to CloudFront only. API Gateway remains a custom origin, not publicly advertised.

## Consequences

**Positive**

- Single URL for users (`https://short.example/demo`)
- One TLS certificate and DNS record
- Redirect slugs work at the root path (`/{slug}`)
- CloudFront caching reduces S3 origin load for static assets

**Negative**

- Cache behavior ordering is critical — misconfigured patterns can route API paths to S3 or vice versa
- Redirect `/*` catch-all must be evaluated after `/api/*` and static paths
- Frontend updates require CloudFront invalidation

## References

- `terraform/modules/cloudfront/main.tf`
- [Architecture](../architecture.md)
