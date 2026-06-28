# ADR 003: Async click tracking via SQS

## Status

Accepted

## Context

Each redirect should increment a click counter. Options:

1. **Synchronous DynamoDB update** in the redirect Lambda before returning 302
2. **Async queue** — enqueue event, separate consumer updates count
3. **Analytics only via CloudWatch / logs** — no per-link count

## Decision

Redirect Lambda sends a message to SQS; `click_tracker` Lambda consumes batches and increments `click_count` on the links table.

Queue configuration:

- Main queue: `url-shortener-click-events`
- DLQ after 3 failed receives
- Batch size: 10
- CloudWatch alarm on click tracker errors

## Consequences

**Positive**

- Redirect latency not blocked by DynamoDB write contention
- Natural backpressure under traffic spikes
- Failed increments isolated to DLQ for inspection
- Redirect path stays simple

**Negative**

- Click count is eventually consistent (usually sub-second)
- Additional resources: SQS queues, event source mapping, consumer Lambda
- Slight operational complexity (DLQ monitoring)

## Alternatives considered

Synchronous update was rejected because redirect responsiveness is the primary user-facing path. At demo scale the extra infrastructure cost is negligible.

## References

- `src/redirect/handler.py` — `sqs.send_message`
- `src/click_tracker/handler.py` — batch increment
- `terraform/modules/sqs/main.tf`
