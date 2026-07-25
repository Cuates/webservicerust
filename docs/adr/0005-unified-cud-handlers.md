# Architecture Decision Record
# 0005. Unified CUD Handlers and Secure Proxy IP Extraction

## Status
Accepted

## Context
During the evolution of our Axum HTTP routing layer, we experienced fragmentation in our handler files. Specifically, `post.rs`, `put.rs`, `delete.rs`, and custom query logic in `query.rs` were split across multiple files. This separation scattered related data manipulation (Create, Update, Delete) operations, making the `newsfeed-server` routing layer harder to maintain and test coherently.

Additionally, our infrastructure required a resilient approach to API rate-limiting when deployed behind a reverse proxy or load balancer. The `tower_governor` token-bucket rate limiter defaults to evaluating the immediate downstream peer IP. Without proper extraction of headers like `X-Forwarded-For` or `X-Real-IP`, the rate limiter would mistakenly identify all inbound traffic as originating from a single IP (the load balancer), unfairly dropping legitimate user requests.

## Decision
We decided to implement two structural changes to the `newsfeed-server` crate:

1. **Unified CUD Handlers**: We merged the fragmented `POST`, `PUT`, `DELETE`, and `query` handlers into a single, unified `cud.rs` module. The `GET` (Read) operations remain in `get.rs` to clearly separate read-heavy logic from write-heavy (mutating) operations.
2. **Secure Proxy IP Extractor**: We implemented a new `ip_extractor.rs` middleware. This custom proxy fallback securely parses `X-Forwarded-For` and `X-Real-IP` headers to accurately resolve the original client IP. This extracted IP is then forwarded into the `tower_governor` rate-limiting layer.

## Consequences
- **Positive**: Cleaned up the `newsfeed-server/src/handlers/` file tree, establishing a clear separation between Read (`get.rs`) and Mutate (`cud.rs`) boundaries.
- **Positive**: Enhanced resilience and security against DDoS attacks when deployed behind load balancers, ensuring legitimate traffic isn't globally rate-limited due to proxy IP spoofing.
- **Negative**: Git history for the deleted handler files (`post.rs`, `put.rs`, etc.) is disjointed from the new `cud.rs` implementation.
