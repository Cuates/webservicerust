# 4. Security and Resiliency Enforcements (Batching & Rate Limiting)

Date: 2026-07-20

## Status

Accepted

## Context

As the Newsfeed web service prepares for public deployment, the API was highly vulnerable to resource exhaustion. Malicious actors or misconfigured clients could send multi-megabyte JSON arrays in a single request, tying up database connections and exhausting memory. Additionally, API key authentication was susceptible to brute-force and timing side-channel attacks.

## Decision

To proactively protect the application resources:
1. **Middleware Ordering**: We integrated `tower_governor` for token-bucket rate limiting and explicitly placed it *before* the `ApiKeyLayer` in the Axum middleware stack. This ensures IPs are blocked before we spend compute cycles verifying headers.
2. **Timing-Attack Resistance**: API Keys are now hashed via `SHA-256` upon application boot. The `ApiKeyLayer` hashes the incoming HTTP header and compares the hashes securely to mitigate side-channel timing attacks.
3. **Batch Limits**: A strict `500-item` batch limit was enforced in the `newsfeed-service` payload validator for all bulk CUD (Create, Update, Delete) operations. Payloads exceeding this threshold are immediately rejected with a `HTTP 400 Bad Request`.
4. **ETag Hashing**: Replaced `sha2` with `xxhash-rust` to significantly increase the performance of processing large JSON response ETags.

## Consequences

- Clients sending massive batches will now experience breaking `HTTP 400` errors if they do not chunk their requests into sets of 500 or fewer.
- The service will require less memory overhead per request, and the database connection pools will not be starved by single massive transactions.
- API Key validations are heavily insulated from brute force due to the upstream IP rate limiter.
