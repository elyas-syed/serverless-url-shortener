# Operations

## Monitoring

### CloudWatch log groups

All Lambdas log to CloudWatch with 7-day retention:

| Log group | Function |
|-----------|----------|
| `/aws/lambda/url-shortener-create-link` | Create API |
| `/aws/lambda/url-shortener-redirect` | Redirects |
| `/aws/lambda/url-shortener-get-analytics` | Metadata / delete |
| `/aws/lambda/url-shortener-click-tracker` | SQS consumer |

View recent errors:

```bash
aws logs tail /aws/lambda/url-shortener-redirect --since 1h --follow
```

### CloudWatch alarm

`url-shortener-click-tracker-errors` fires when the click tracker Lambda reports any errors in a 60-second period. Check the DLQ if clicks are not incrementing.

### SQS DLQ

Queue: `url-shortener-click-events-dlq`

Inspect failed messages:

```bash
aws sqs receive-message \
  --queue-url "$(terraform -chdir=terraform output -raw click_events_queue_url | sed 's/click-events/click-events-dlq/')"
```

## Common tasks

### Update Lambda code

```bash
make build
cd terraform && terraform apply
```

### Update frontend

```bash
cd terraform && terraform apply
aws cloudfront create-invalidation \
  --distribution-id "$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='url-shortener URL shortener'].Id" --output text)" \
  --paths "/index.html" "/assets/*"
```

### Change default TTL or rate limits

Edit `terraform.tfvars`, then `terraform apply`. Lambdas pick up new environment variables without code changes.

### Manually deactivate a link

In `auth_mode = "api_key"`:

```bash
curl -X DELETE "$APP_URL/api/links/my-slug" -H "x-api-key: YOUR_KEY"
```

In demo mode, use the AWS console to set `is_active = false` on the DynamoDB item.

## Troubleshooting

### Redirect returns 404

- Confirm slug exists in `url-shortener-links` table
- Check `is_active` is `true`
- Verify CloudFront `/*` behavior routes to API Gateway (not S3)
- Ensure slug is not a reserved path (`api`, `health`, etc.)

### Redirect returns 410

Link TTL expired. DynamoDB TTL deletes items asynchronously after `expires_at`.

### Create returns 429

Per-IP rate limit hit. Wait 60 seconds or lower traffic from that IP. Adjust `rate_limit_per_minute` in tfvars if needed.

### Stale web UI after deploy

CloudFront cache. Run invalidation for `/index.html` and `/assets/*`.

### Click count not updating

1. Check `url-shortener-click-tracker` logs for errors
2. Inspect DLQ for poison messages
3. Confirm SQS event source mapping is enabled

### `terraform apply` fails on Lambda zip

Run `make build` first. Terraform expects `dist/*.zip` at plan time for `source_code_hash`.

### API works on API Gateway URL but not custom domain

- Verify Route53 alias points to CloudFront
- Check ACM certificate status is `ISSUED`
- Confirm CloudFront alternate domain name matches `domain_name`

## Destroying infrastructure

```bash
cd terraform
terraform destroy
```

Bootstrap state bucket is a separate stack with `prevent_destroy = true`. Remove that lifecycle guard before destroying the bucket if you intend to delete it.
