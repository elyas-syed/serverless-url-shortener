# ADR 001: S3 native lockfile over DynamoDB state locking

## Status

Accepted

## Context

Terraform remote state on S3 traditionally used a DynamoDB table for state locking. Terraform 1.10+ introduced native S3 lockfile support via `use_lockfile = true` in the S3 backend configuration.

## Decision

Use S3 native lockfile locking instead of a DynamoDB lock table in the bootstrap stack.

Bootstrap provisions:

- Versioned S3 bucket (required for lockfile)
- SSE encryption and public access block
- 90-day lifecycle expiration for noncurrent state versions
- `use_lockfile = true` in `backend_config` output

## Consequences

**Positive**

- One fewer AWS resource to manage and pay for
- Simpler bootstrap stack
- Locking co-located with state storage

**Negative**

- Requires Terraform >= 1.10
- Team must use compatible Terraform versions
- Versioning increases storage slightly (mitigated by lifecycle rule)

## References

- [Terraform S3 backend lockfile](https://developer.hashicorp.com/terraform/language/backend/s3)
- `terraform/bootstrap/main.tf`
- `terraform/versions.tf`
