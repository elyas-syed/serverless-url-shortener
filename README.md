# AWS URL Shortener

Production-style serverless URL shortener on AWS using Terraform, Lambda, DynamoDB, SQS, API Gateway, CloudFront, and a static S3 frontend.

## Features

- Shorten URLs via web UI or REST API
- Custom slugs and link expiration (DynamoDB TTL)
- Async click analytics via SQS
- Demo mode: open create API with 5 requests/min/IP rate limit
- Upgrade path to API key auth via `auth_mode` variable

## Architecture

```
Browser → CloudFront → S3 (landing page)
                     → API Gateway → Lambda → DynamoDB / SQS
                     → Lambda (redirects)
```

## Prerequisites

- AWS account with credentials configured
- Terraform >= 1.10 (required for S3 native state lockfile)
- Python 3.12+
- `make`, `zip`

Optional: custom domain in Route53

## Quick start

### 1. Bootstrap remote state (one time)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit state_bucket_name to a globally unique value
terraform init
terraform apply
```

Copy the `backend_config` output into the `backend "s3"` block in `terraform/versions.tf` (uses `use_lockfile = true` instead of DynamoDB), then:

```bash
cd ../
terraform init
```

### 2. Build Lambda packages

```bash
make build
make test
```

### 3. Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform plan
terraform apply
```

Note the `app_url` output — that is your public shortener URL.

### 4. Demo

Browser: open `app_url`, paste a URL, click Shorten.

Terminal:

```bash
chmod +x scripts/demo.sh
./scripts/demo.sh "$(terraform -chdir=terraform output -raw app_url)"
```

## API

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/links` | Create a short link |
| GET | `/api/links/{slug}` | Link metadata and click count |
| GET | `/{slug}` | Redirect to long URL |
| GET | `/health` | Health check |

Create example:

```bash
curl -X POST "$APP_URL/api/links" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","slug":"demo"}'
```

## Estimated monthly cost (demo traffic)

~**$1–2/month** without WAF or custom domain overhead beyond Route53 ($0.50/zone if needed).

## Switching to API key auth

Set in `terraform.tfvars`:

```hcl
auth_mode = "api_key"
```

Then apply. (Usage plan wiring is prepared for a follow-up PR.)

## Project layout

```
terraform/          Root stack and modules
src/                Python Lambda handlers
web/                Static frontend
docs/               Architecture, API, deployment, and operations guides
tests/              Unit tests
scripts/demo.sh     End-to-end demo script
```

## Documentation

See [docs/](docs/) for architecture, API reference, deployment runbook, security notes, and more.

## Contributing

Use feature branches and pull requests:

```bash
git checkout -b feat/my-change
# ... make changes, commit ...
git push -u origin feat/my-change
gh pr create --base main --head feat/my-change
```
