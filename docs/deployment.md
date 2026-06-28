# Deployment

## Prerequisites

- AWS account with credentials configured (`aws sts get-caller-identity`)
- Terraform >= 1.10 (S3 native state lockfile)
- Python 3.12+
- `make`, `zip`

Optional for custom domain:

- Route53 hosted zone for your domain
- ACM certificate (created automatically by Terraform in `us-east-1` for CloudFront)

## One-time: bootstrap remote state

The bootstrap stack in `terraform/bootstrap/` creates the S3 bucket for Terraform state.

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Set state_bucket_name to a globally unique value
terraform init
terraform apply
```

Copy the `backend_config` output into the `backend "s3"` block in `terraform/versions.tf`:

```hcl
backend "s3" {
  bucket       = "your-unique-state-bucket"
  key          = "url-shortener/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

Then reinitialize the root stack:

```bash
cd ../
terraform init
```

See [ADR 001](decisions/001-s3-lockfile-over-dynamodb-lock.md) for why native lockfile is used.

## Deploy the application

### 1. Configure variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` for your environment. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | Primary region |
| `auth_mode` | `open` | `open` or `api_key` |
| `rate_limit_per_minute` | `5` | Create API rate limit |
| `default_link_ttl_days` | `3` | Default link expiration |
| `domain_name` | `""` | Custom domain (optional) |
| `hosted_zone_id` | `""` | Route53 zone ID (required with domain) |

### 2. Build Lambda packages

From the repository root:

```bash
make build
make test   # optional but recommended
```

Lambda zips are written to `dist/*.zip`. Terraform references these paths directly.

### 3. Plan and apply

```bash
cd terraform
terraform plan
terraform apply
```

### 4. Note outputs

```bash
terraform output app_url
terraform output api_endpoint
```

`app_url` is the public URL (custom domain or CloudFront). Use it for the web UI and API.

## Custom domain

Set in `terraform.tfvars`:

```hcl
domain_name    = "short.example.com"
hosted_zone_id = "Z0123456789ABCDEFGHIJ"
```

Terraform will:

1. Request an ACM certificate in `us-east-1` (CloudFront requirement)
2. Create DNS validation records in Route53
3. Attach the certificate to CloudFront
4. Create an alias `A` record pointing to the distribution

`BASE_URL` is passed to Lambdas so `short_url` in API responses uses your domain.

## Updating after code changes

### Lambda changes

```bash
make build
cd terraform && terraform apply
```

Terraform detects zip hash changes via `source_code_hash` and updates each function.

### Frontend changes

Static files in `web/` are uploaded by the `frontend` module. After apply:

```bash
# Get distribution ID from state or AWS console
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/index.html" "/assets/*"
```

CloudFront caches `index.html` and `/assets/*` with TTL up to 24 hours. Invalidate after UI deploys.

### Terraform-only changes

```bash
cd terraform && terraform apply
```

No `make build` needed unless Lambda code changed.

## Demo script

```bash
chmod +x scripts/demo.sh
./scripts/demo.sh "$(terraform -chdir=terraform output -raw app_url)"
```

Creates a link, checks redirect headers, and fetches analytics.

## Deployment checklist

- [ ] Bootstrap state bucket applied (if using remote state)
- [ ] `terraform.tfvars` configured (not committed)
- [ ] `make build` completed
- [ ] `terraform apply` succeeded
- [ ] `app_url` loads the web UI
- [ ] `scripts/demo.sh` passes
- [ ] CloudFront invalidation run after frontend updates
