# Documentation

Project documentation for the AWS serverless URL shortener. The [README](../README.md) covers quick start; these pages go deeper.

## Guides

| Document | Description |
|----------|-------------|
| [Architecture](architecture.md) | System design, request flows, and data model |
| [API reference](api.md) | REST endpoints, schemas, and error codes |
| [Deployment](deployment.md) | Bootstrap, deploy, custom domain, and runbook |
| [Security](security.md) | Auth modes, validation, rate limits, and production hardening |
| [Terraform](terraform.md) | Module layout, variables, and extension guide |
| [Operations](operations.md) | Monitoring, troubleshooting, and day-2 tasks |
| [Development](development.md) | Local build, test, and contribution workflow |
| [Cost](cost.md) | Estimated monthly spend and scaling factors |
| [Roadmap](roadmap.md) | Planned features and known gaps |

## Architecture decisions

| ADR | Title |
|-----|-------|
| [001](decisions/001-s3-lockfile-over-dynamodb-lock.md) | S3 native lockfile over DynamoDB state locking |
| [002](decisions/002-cloudfront-single-entry.md) | CloudFront as single public entry point |
| [003](decisions/003-async-click-tracking-via-sqs.md) | Async click tracking via SQS |
