//! Database configuration loaded from environment variables.
//! Only the configuration for the active `DATABASE_TARGET` needs to be set.

use newsfeed_constants::db::DatabaseType;

/// Which database engine the service routes to at runtime.
/// Controlled by the `DATABASE_TARGET` environment variable.
pub type DatabaseTarget = DatabaseType;

/// Database connection parameters loaded from environment variables.
#[derive(serde::Deserialize, Debug, Clone)]
pub struct DatabaseConfig {
    /// Active database engine (`postgres` | `mariadb` | `mssql`).
    pub database_target: DatabaseTarget,

    // ── PostgreSQL ───────────────────────────────────────────────────────────
    /// Full connection URL, e.g. `postgresql://user:pass@host:5432/dbname`
    pub postgres_url: Option<String>,

    // ── MariaDB ──────────────────────────────────────────────────────────────
    /// Full connection URL, e.g. `mysql://user:pass@host:3306/dbname?charset=utf8mb4`
    pub mariadb_url: Option<String>,

    // ── MSSQL (tiberius — no ODBC required) ──────────────────────────────────
    pub mssql_host:     Option<String>,
    pub mssql_port:     Option<u16>,
    pub mssql_database: Option<String>,
    pub mssql_username: Option<String>,
    pub mssql_password: Option<String>,
}

impl DatabaseConfig {
    /// Validate that the required env vars for the active target are present.
    /// Panics with a descriptive message if any are missing.
    pub fn validate(&self) {
        match self.database_target {
            DatabaseTarget::Postgres => {
                if self.postgres_url.is_none() {
                    panic!("DATABASE_TARGET=postgres but POSTGRES_URL is not set");
                }
            }
            DatabaseTarget::MariaDb => {
                if self.mariadb_url.is_none() {
                    panic!("DATABASE_TARGET=mariadb but MARIADB_URL is not set");
                }
            }
            DatabaseTarget::MsSql => {
                let missing: Vec<&str> = [
                    ("MSSQL_HOST",     self.mssql_host.is_none()),
                    ("MSSQL_DATABASE", self.mssql_database.is_none()),
                    ("MSSQL_USERNAME", self.mssql_username.is_none()),
                    ("MSSQL_PASSWORD", self.mssql_password.is_none()),
                ]
                .iter()
                .filter_map(|(name, absent)| if *absent { Some(*name) } else { None })
                .collect();

                if !missing.is_empty() {
                    panic!(
                        "DATABASE_TARGET=mssql but the following env vars are not set: {}",
                        missing.join(", ")
                    );
                }
            }
        }
    }
}
