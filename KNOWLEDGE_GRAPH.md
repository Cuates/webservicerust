# Knowledge Graph

```mermaid
graph TD
    %% Core Inputs
    ENV[".env (API_KEYS, DATABASE_TARGET)"] --> Config[newsfeed-config]
    Client[HTTP Client] --> Server["newsfeed-server (Axum)"]
    
    %% Request Flow
    Server --> |Validates Rate Limit & API Key| Router
    Router --> |Deser| Models["newsfeed-models (ExtractParams/CudParams)"]
    Router --> Service["newsfeed-service (Business Logic)"]
    Service --> |Validates Payload| DB[newsfeed-db]
    
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
- **Authentication**: `X-API-Key` HTTP Header -> `HashSet<String>` in `AppState`.
- **Database Routing**: `DATABASE_TARGET` env var -> Instantiates specific `DbPool` enum variant -> Routes to `postgres.rs`, `mariadb.rs`, or `mssql.rs`.
- **Legacy Python**: `constants.py` -> `newsfeed-constants`; `newsfeedwebservice.py` -> `newsfeed-service` & `newsfeed-server`.
- **Error Standardization**: Malformed payloads -> `AppJson` Extractor -> Structured JSON mapped to unified constants (e.g. `Code: "BAD_REQUEST"`).
- **Build System**: `cargo-make` (`Makefile.toml`) powers all cross-platform builds and checks.
- **Continuous Integration**: GitHub Actions workflows execute `cargo make test-coverage` to strictly enforce minimum code coverage thresholds, and a separate `newsfeed-release.yml` pipeline automates cross-platform builds and artifact bundling on version tags.
