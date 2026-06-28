# Cost

Estimated monthly cost for **demo-scale traffic** (hundreds of redirects/day, occasional link creation).

## Summary

| Scale | Estimated cost |
|-------|----------------|
| Demo / portfolio | **~$1–2/month** |
| Light production (10k redirects/day) | ~$5–15/month |
| With WAF | +$5/month minimum |

Costs vary by region and actual usage. Use the [AWS Pricing Calculator](https://calculator.aws/) for precise estimates.

## Service breakdown (demo scale)

### Lambda

- 4 functions, 256 MB, typically sub-second duration
- Free tier covers most demo usage
- **~$0–0.50/month** beyond free tier

### DynamoDB (on-demand)

- `links` table: low read/write volume
- `rate_limits` table: one write per create request, TTL auto-cleanup
- **~$0–1/month**

### API Gateway HTTP API

- Charged per million requests
- Demo traffic is negligible
- **~$0–0.50/month**

### CloudFront

- PriceClass_100 (US, Canada, Europe)
- Minimal data transfer for static assets + redirect responses
- **~$0–1/month**

### S3

- Frontend bucket: few KB of static files
- State bucket (bootstrap): versioned state objects, lifecycle expires old versions
- **~$0.10/month**

### SQS

- Click events: one message per redirect
- Free tier covers demo volume
- **~$0/month**

### Route53 (optional)

- Hosted zone: **$0.50/month** per zone
- Queries: negligible at demo scale

### ACM

- Public certificates: **free**

## What increases cost

| Factor | Impact |
|--------|--------|
| Higher redirect volume | Lambda, API Gateway, CloudFront data transfer |
| WAF on CloudFront | ~$5+/month base + per-request charges |
| CloudWatch log retention > 7 days | Storage charges |
| Multi-region deployment | Duplicated resources |
| Provisioned DynamoDB | Only if on-demand is insufficient |

## Cost optimizations already in place

- DynamoDB on-demand (no idle provisioned capacity)
- CloudFront PriceClass_100 (cheapest edge locations)
- SQS async click tracking (redirect path stays fast, batches writes)
- 7-day CloudWatch log retention
- 90-day lifecycle on state bucket noncurrent versions

## Production cost additions

When moving beyond demo mode, budget for:

- **AWS WAF** — bot protection and rate-based rules
- **SNS** — alarm notifications
- **Secrets Manager** — if storing API keys outside Terraform
- **Higher CloudFront traffic** — viral links or marketing campaigns

See [Security](security.md) for the production hardening checklist.
