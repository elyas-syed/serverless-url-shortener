# Blog outline: Building a serverless URL shortener on AWS

## 1. Introduction
- Why build a URL shortener as a learning project
- Goals: serverless, low cost, demo-friendly

## 2. Architecture
- CloudFront as single entry point
- Lambda for create, redirect, analytics
- DynamoDB + SQS for storage and async clicks
- Diagram from README

## 3. Terraform module design
- Single environment, composable modules
- Bootstrap stack for remote state

## 4. Security trade-offs (demo mode)
- Open API with rate limiting vs API keys
- Input validation and SSRF protection
- Why WAF was skipped for cost

## 5. Live demo walkthrough
- Web UI screenshot flow
- curl examples from scripts/demo.sh

## 6. Cost breakdown
- ~$1–2/month at demo scale
- What to add when going production (WAF, API keys)

## 7. Lessons learned
- CloudFront path routing for SPA + redirects
- Per-IP rate limits with DynamoDB TTL
- Makefile gotcha: subshells in build loops

## 8. Next steps
- API key auth
- Custom domain
- CI/CD with GitHub Actions
