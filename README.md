# AWS URL Shortener

**Short links. Zero servers. Built on AWS.**

A deployable Production grade serverless URL shortener with a web UI, REST API, click analytics, and link expiration with no servers to manage. 

Built with Terraform, Lambda, DynamoDB, SQS, API Gateway, CloudFront, and S3, production-ready and ~$1–2/month at demo scale.

**Full Documentation** — architecture, API reference, deployment, and more — is in **[`docs/`](docs/)** ([index](docs/README.md)).

<details>
<summary><strong>View web UI screenshot</strong> · <a href="https://elyas.click">elyas.click</a></summary>
<br>
<p align="center">
  <a href="https://elyas.click">
    <img src="assets/images/web-ui.jpg" alt="elyas.click URL shortener — shorten a link and view click stats" width="560">
  </a>
</p>
</details>

<details>
<summary><strong>View architecture diagram</strong> · <a href="https://app.eraser.io/workspace/NjIOU5jPmHgeOj4OvVmO?diagram=r8o0_JSJPUNXFo8IWrvh&layout=canvas">Eraser</a></summary>
<br>
<p align="center">
  <a href="https://app.eraser.io/workspace/NjIOU5jPmHgeOj4OvVmO?diagram=r8o0_JSJPUNXFo8IWrvh&layout=canvas">
    <img src="assets/images/architecture.png" alt="AWS URL Shortener serverless architecture — CloudFront, Lambda, DynamoDB, SQS" width="900">
  </a>
</p>
</details>

## Features

- Shorten URLs via web UI or REST API
- Custom slugs and link expiration (default **3 days**, DynamoDB TTL)
- Async click analytics via SQS
- Demo mode: open create API with 5 requests/min/IP rate limit
- Upgrade path to API key auth via `auth_mode` variable

## Architecture

```
Browser → CloudFront → S3 (landing page)
                     → API Gateway → Lambda → DynamoDB / SQS
                     → Lambda (redirects)
```

High-resolution diagram (horizontal layout, blog-friendly): [`assets/images/architecture.png`](../assets/images/architecture.png) · [Edit in Eraser](https://app.eraser.io/workspace/NjIOU5jPmHgeOj4OvVmO?diagram=r8o0_JSJPUNXFo8IWrvh&layout=canvas)

For request flows, data model, CloudFront routing, and design rationale, see [docs/architecture.md](docs/architecture.md).

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

Note the `app_url` output — that is your public shortener URL. See [docs/deployment.md](docs/deployment.md) for custom domain setup, updates, and CloudFront invalidation.

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
| DELETE | `/api/links/{slug}` | Soft-delete (requires `api_key` auth) |
| GET | `/{slug}` | Redirect to long URL |
| HEAD | `/{slug}` | Redirect headers only |
| GET | `/health` | Health check |

Full request/response schemas, validation rules, and error codes: [docs/api.md](docs/api.md).

```bash
curl -X POST "$APP_URL/api/links" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","slug":"demo"}'
```

## Cost

~**$1–2/month** at demo traffic. Breakdown and scaling factors: [docs/cost.md](docs/cost.md).

## API key auth

Set `auth_mode = "api_key"` in `terraform.tfvars` and apply. Usage plan wiring is planned — see [docs/security.md](docs/security.md) and [docs/roadmap.md](docs/roadmap.md).

## Project layout

```
terraform/          Root stack and modules
src/                Python Lambda handlers
web/                Static frontend
docs/               Detailed guides (architecture, API, deployment, …)
assets/images/      Screenshots and architecture diagram (PNG)
tests/              Unit tests
scripts/demo.sh     End-to-end demo script
```

## Contributing

Feature branches and pull requests. Full dev workflow: [docs/development.md](docs/development.md).

```bash
git checkout -b feat/my-change
# ... make changes, commit ...
git push -u origin feat/my-change
gh pr create --base main --head feat/my-change
```
