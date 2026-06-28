# Architecture decisions

Recorded design choices for the URL shortener project.

---

## ADR 001: S3 native lockfile over DynamoDB state locking

**Status:** Accepted

### Context

Terraform remote state on S3 traditionally used a DynamoDB table for state locking. Terraform 1.10+ introduced native S3 lockfile support via `use_lockfile = true` in the S3 backend configuration.

### Decision

Use S3 native lockfile locking instead of a DynamoDB lock table in the bootstrap stack.

Bootstrap provisions:

- Versioned S3 bucket (required for lockfile)
- SSE encryption and public access block
- 90-day lifecycle expiration for noncurrent state versions
- `use_lockfile = true` in `backend_config` output

### Consequences

**Positive**

- One fewer AWS resource to manage and pay for
- Simpler bootstrap stack
- Locking co-located with state storage

**Negative**

- Requires Terraform >= 1.10
- Team must use compatible Terraform versions
- Versioning increases storage slightly (mitigated by lifecycle rule)

### References

- [Terraform S3 backend lockfile](https://developer.hashicorp.com/terraform/language/backend/s3)
- `terraform/bootstrap/main.tf`
- `terraform/versions.tf`

---

## ADR 002: CloudFront as single public entry point

**Status:** Accepted

### Context

The application serves both a static web UI and a dynamic API (create links, redirects, analytics). Options included:

1. Separate CloudFront distributions for S3 and API Gateway
2. Direct API Gateway URL for API, CloudFront for static only
3. Single CloudFront distribution with multiple origins and path-based behaviors

### Decision

Use one CloudFront distribution with two origins:

- **S3** — landing page, `index.html`, `/assets/*`
- **API Gateway** — `/api/*`, `/health`, and `/*` (short-link redirects)

Custom domain (optional) attaches to CloudFront only. API Gateway remains a custom origin, not publicly advertised.

### Consequences

**Positive**

- Single URL for users (`https://short.example/demo`)
- One TLS certificate and DNS record
- Redirect slugs work at the root path (`/{slug}`)
- CloudFront caching reduces S3 origin load for static assets

**Negative**

- Cache behavior ordering is critical — misconfigured patterns can route API paths to S3 or vice versa
- Redirect `/*` catch-all must be evaluated after `/api/*` and static paths
- Frontend updates require CloudFront invalidation

### References

- `terraform/modules/cloudfront/main.tf`
- [Architecture](../architecture.md)

---

## ADR 003: Async click tracking via SQS

**Status:** Accepted

### Context

Each redirect should increment a click counter. Options:

1. **Synchronous DynamoDB update** in the redirect Lambda before returning 302
2. **Async queue** — enqueue event, separate consumer updates count
3. **Analytics only via CloudWatch / logs** — no per-link count

### Decision

Redirect Lambda sends a message to SQS; `click_tracker` Lambda consumes batches and increments `click_count` on the links table.

Queue configuration:

- Main queue: `url-shortener-click-events`
- DLQ after 3 failed receives
- Batch size: 10
- CloudWatch alarm on click tracker errors

### Consequences

**Positive**

- Redirect latency not blocked by DynamoDB write contention
- Natural backpressure under traffic spikes
- Failed increments isolated to DLQ for inspection
- Redirect path stays simple

**Negative**

- Click count is eventually consistent (usually sub-second)
- Additional resources: SQS queues, event source mapping, consumer Lambda
- Slight operational complexity (DLQ monitoring)

### Alternatives considered

Synchronous update was rejected because redirect responsiveness is the primary user-facing path. At demo scale the extra infrastructure cost is negligible.

### References

- `src/redirect/handler.py` — `sqs.send_message`
- `src/click_tracker/handler.py` — batch increment
- `terraform/modules/sqs/main.tf`
