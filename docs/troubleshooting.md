# Troubleshooting

This guide helps diagnose and resolve common issues encountered when setting up or running the Newsfeed web service.

## 1. Startup Panics (Configuration Errors)

The service enforces strict configuration validation at startup. If it fails to boot, check the console output.

- **Error: `missing environment variable API_KEYS`**
  You haven't defined the `API_KEYS` variable in your `.env` file. Run the `generate-api-key` script to populate it.
  
- **Error: `missing environment variable DATABASE_TARGET`**
  The application needs to know which database engine to connect to. Set `DATABASE_TARGET` to `postgres`, `mariadb`, or `mssql` in your `.env` file.

- **Error: `missing environment variable <DB_URL>`**
  Ensure the URL matching your `DATABASE_TARGET` is defined (e.g., if `DATABASE_TARGET=mssql`, `MSSQL_DB_URL` must be set).

## 2. Database Connection Failures

- **Issue**: The application panics with a `sqlx` or `tiberius` connection error at startup.
- **Solution**: 
  - Verify that your database is running and accessible from the machine (or Docker network) running the service.
  - If using Docker Desktop, use `host.docker.internal` in your DB URL instead of `localhost` or `127.0.0.1` to access a database running on your host machine.
  - Ensure the credentials in the DB URL are correct and have appropriate schema permissions.

## 3. API Returns `401 Unauthorized`

- **Issue**: You receive an `HTTP 401 Unauthorized` for all endpoints.
- **Solution**: Ensure your client application (like the Angular frontend) is injecting the correct `X-API-Key` HTTP header. 
  - Compare the key your client is sending with the active keys in your `.env` file (`API_KEYS`).
  - If running behind a reverse proxy, ensure the proxy isn't stripping the `X-API-Key` header.

## 4. API Returns `429 Too Many Requests`

- **Issue**: You receive an `HTTP 429 Too Many Requests` response.
- **Solution**: You are hitting the `tower_governor` rate limiter. 
  - By default, the limit is `10` requests per second per IP. This occurs *before* API key validation to proactively drop malicious traffic.
  - Increase this threshold by setting `RATE_LIMIT_RPS` and `RATE_LIMIT_BURST` to higher values in your `.env` file.
  - Note: If deploying behind a load balancer without proper IP forwarding (`X-Forwarded-For`), the load balancer's IP might trigger the limit for all users. Ensure your load balancer preserves the original client IP.

## 5. API Returns `415 Unsupported Media Type`, `422 Unprocessable Entity`, or `400 Bad Request`

- **Issue**: You send a payload and receive an HTTP error status such as `415`, `422`, or `400`.
- **Solution**: 
  - **HTTP 415**: Ensure you are sending the `Content-Type: application/json; charset=utf-8` header. The payload validator is extremely strict and requires the charset to be explicitly defined.
  - **HTTP 422**: You are sending extra or unrecognized JSON keys in your payload. All domain models enforce `#[serde(deny_unknown_fields)]` to reject malformed or inflated requests with a structured `VALIDATION_ERROR` code.
  - **HTTP 400**: Verify your JSON syntax is valid and does not exceed the strict **500-item batch limit** for bulk operations.
  - Our custom `AppJson` extractor masks raw stack traces and instead maps errors to structured responses using unified constants (e.g., `Code: "BAD_REQUEST"`, `Code: "VALIDATION_ERROR"`) to prevent data leaks.

## 6. API Returns `404 Not Found` with JSON Body

- **Issue**: You request an unmapped endpoint or route and receive an HTTP 404 response.
- **Solution**: The application uses a fallback handler (`not_found.rs`) that returns a structured JSON error envelope (`Code: "NOT_FOUND"`, `Message: "The requested resource or endpoint does not exist"`) rather than default browser HTML or empty responses. Check your URL path against the OpenAPI spec at `/swagger-ui`.

## 7. API Returns CORS Errors (or Missing Headers)

- **Issue**: The browser blocks the request, or a preflight `OPTIONS` request returns a `200 OK` but lacks `Access-Control-Allow-Origin` headers.
- **Solution**: The `tower_http::cors::CorsLayer` aggressively drops CORS headers if the incoming `Origin` header does not match the configured whitelist, deliberately failing the browser check. Verify the client's Origin matches the allowed list in `newsfeed-server/src/router.rs`.

## 8. Docker Build Failures

- **Issue**: `cargo build` succeeds locally but the `docker build` fails.
- **Solution**: Ensure your `.dockerignore` file correctly excludes the `target/` directory and any local `.env` files. Passing a massive local `target/` directory to the Docker build context can cause memory exhaustion and out-of-space errors on the Docker daemon.

## 9. Test Coverage Threshold Failures

- **Issue**: `cargo make test-coverage` or the CI pipeline fails with `Error: coverage is below the required threshold`.
- **Solution**: 
  - We enforce strict code coverage thresholds across the workspace (>99% line and function coverage).
  - The coverage table will print at the bottom of the test run to highlight exactly which files are missing coverage.
  - You must write unit tests (in the respective crate) or integration tests (in `newsfeed-server/tests/integration_test.rs`) to bump the coverage above the thresholds before committing.
  - When testing against live databases, remember you can bypass `testcontainers` using `TEST_POSTGRES_URL`, `TEST_MARIADB_URL`, or `TEST_MSSQL_URL` (and `TEST_MSSQL_PORT`).
