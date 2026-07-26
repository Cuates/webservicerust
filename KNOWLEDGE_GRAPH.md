# Knowledge Graph

```mermaid
graph TD
    %% Core Inputs
    ENV[".env (API_KEYS, DATABASE_TARGET)"] --> Config[newsfeed-config]
    Client[HTTP Client] --> Server["newsfeed-server (Axum)"]
    
    %% Request Flow
    Server --> |Rate Limits (ip_extractor + tower_governor) & Validates API Key (SHA-256)| Router
    Router --> |Deser| Models["newsfeed-models (ExtractParams/CudParams)"]
    Router --> Service["newsfeed-service (Business Logic)"]
    Service --> |Validates Payload (500-item batch limit)| DB[newsfeed-db]
    
    %% Dependency Arrows (Crate Level)
    Server -.-> Service
    Server -.-> Config
    Server -.-> Models
    Service -.-> DB
    Service -.-> Models
    DB -.-> Models
    DB -.-> Constants[newsfeed-constants]
    
    %% DB Engines
    DB --> |sqlx| Postgres[(PostgreSQL)]
    DB --> |sqlx| MariaDB[(MariaDB)]
    DB --> |tiberius| MSSQL[(MSSQL)]
    
    %% Testing
    TestSuite[axum-test / testcontainers] -.-> |Integration Tests| Server
    TestSuite -.-> |Provisions Ephemeral DBs| Postgres
    TestSuite -.-> |Provisions Ephemeral DBs| MariaDB
    TestSuite -.-> |Provisions Ephemeral DBs| MSSQL
```

## Conceptual Mappings
- **Authentication**: `X-API-Key` HTTP Header -> `SHA-256` hash comparison -> `HashSet<String>` in `AppState`.
- **Resiliency**: IP-based Rate Limiting (powered by `ip_extractor` secure proxy fallback) occurs *before* Auth to proactively drop malicious connections. All batch processing strictly limits arrays to `500` items. Inbound JSON payloads enforce strict schema validation via `#[serde(deny_unknown_fields)]`.
- **Database Routing**: `DATABASE_TARGET` env var -> Instantiates specific `DbPool` enum variant -> Routes to `postgres.rs`, `mariadb.rs`, or `mssql.rs`.
- **Legacy Python**: `constants.py` -> `newsfeed-constants`; `newsfeedwebservice.py` -> `newsfeed-service` & `newsfeed-server`.
- **Error Standardization**: Malformed payloads -> `AppJson` Extractor -> Structured JSON mapped to unified constants (e.g. `Code: "BAD_REQUEST"`).
- **Dependency Hygiene**: Strict auditing via `cargo-machete` prevents unused crates across the workspace.
- **Build System**: `cargo-make` (`Makefile.toml`) powers all cross-platform builds and checks.
- **Continuous Integration**: GitHub Actions workflows execute `cargo make test-coverage` to strictly enforce minimum >99% line and function code coverage thresholds, and a separate `newsfeed-release.yml` pipeline automates cross-platform builds and artifact bundling on version tags.
