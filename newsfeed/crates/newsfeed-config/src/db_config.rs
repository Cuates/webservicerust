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
    pub mssql_host: Option<String>,
    pub mssql_port: Option<u16>,
    pub mssql_database: Option<String>,
    pub mssql_username: Option<String>,
    pub mssql_password: Option<String>,

    /// Enable TLS encryption on the MSSQL connection.
    /// `true`  → `EncryptionLevel::Required`  (production / NPM-fronted)
    /// `false` → `EncryptionLevel::NotSupported` (local development without certs)
    ///
    /// Environment variable: `DB_MSSQL_ENCRYPT` (default: `false`)
    #[serde(default = "default_false")]
    pub db_mssql_encrypt: bool,

    /// Trust the server certificate without validation.
    /// Set to `true` only in local development when using a self-signed cert.
    ///
    /// Environment variable: `DB_MSSQL_TRUST_CERT` (default: `false`)
    #[serde(default = "default_false")]
    pub db_mssql_trust_cert: bool,

    // ── Connection pool tuning ───────────────────────────────────────────────
    /// Maximum number of connections in the pool (default: 10).
    ///
    /// Environment variable: `DB_POOL_MAX`
    #[serde(default = "default_pool_max")]
    pub db_pool_max: u32,

    /// Minimum number of idle connections to maintain (default: 2).
    ///
    /// Environment variable: `DB_POOL_MIN`
    #[serde(default = "default_pool_min")]
    pub db_pool_min: u32,

    /// Seconds to wait for a connection from the pool before erroring (default: 5).
    ///
    /// Environment variable: `DB_ACQUIRE_TIMEOUT_SECS`
    #[serde(default = "default_acquire_timeout")]
    pub db_acquire_timeout_secs: u64,
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
                    ("MSSQL_HOST", self.mssql_host.is_none()),
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

fn default_false() -> bool {
    false
}
fn default_pool_max() -> u32 {
    10
}
fn default_pool_min() -> u32 {
    2
}
fn default_acquire_timeout() -> u64 {
    5
}

#[cfg(test)]
mod tests {
    use super::*;
    use newsfeed_constants::db::DatabaseType;

    fn base_config(target: DatabaseType) -> DatabaseConfig {
        DatabaseConfig {
            database_target: target,
            postgres_url: None,
            mariadb_url: None,
            mssql_host: None,
            mssql_port: None,
            mssql_database: None,
            mssql_username: None,
            mssql_password: None,
            db_mssql_encrypt: false,
            db_mssql_trust_cert: false,
            db_pool_max: 10,
            db_pool_min: 2,
            db_acquire_timeout_secs: 5,
        }
    }

    #[test]
    fn test_validate_postgres_ok() {
        let cfg = DatabaseConfig {
            postgres_url: Some("postgres://user:pass@localhost/db".to_owned()),
            ..base_config(DatabaseType::Postgres)
        };
        cfg.validate(); // Must not panic.
    }

    #[test]
    #[should_panic(expected = "POSTGRES_URL is not set")]
    fn test_validate_postgres_missing_url() {
        let cfg = base_config(DatabaseType::Postgres);
        cfg.validate();
    }

    #[test]
    fn test_validate_mariadb_ok() {
        let cfg = DatabaseConfig {
            mariadb_url: Some("mysql://user:pass@localhost/db".to_owned()),
            ..base_config(DatabaseType::MariaDb)
        };
        cfg.validate(); // Must not panic.
    }

    #[test]
    #[should_panic(expected = "MARIADB_URL is not set")]
    fn test_validate_mariadb_missing_url() {
        let cfg = base_config(DatabaseType::MariaDb);
        cfg.validate();
    }

    #[test]
    fn test_validate_mssql_ok() {
        let cfg = DatabaseConfig {
            mssql_host: Some("localhost".to_owned()),
            mssql_port: Some(1433),
            mssql_database: Some("media".to_owned()),
            mssql_username: Some("sa".to_owned()),
            mssql_password: Some("Password123!".to_owned()),
            ..base_config(DatabaseType::MsSql)
        };
        cfg.validate(); // Must not panic.
    }

    #[test]
    #[should_panic(expected = "the following env vars are not set")]
    fn test_validate_mssql_missing_fields() {
        let cfg = base_config(DatabaseType::MsSql);
        cfg.validate();
    }

    #[test]
    fn test_database_type_display() {
        assert_eq!(DatabaseType::Postgres.to_string(), "postgres");
        assert_eq!(DatabaseType::MariaDb.to_string(), "mariadb");
        assert_eq!(DatabaseType::MsSql.to_string(), "mssql");
    }

    #[test]
    fn test_default_pool_values() {
        let cfg = DatabaseConfig {
            postgres_url: Some("postgres://u:p@h/d".to_owned()),
            ..base_config(DatabaseType::Postgres)
        };
        assert_eq!(cfg.db_pool_max, 10);
        assert_eq!(cfg.db_pool_min, 2);
        assert_eq!(cfg.db_acquire_timeout_secs, 5);
        assert!(!cfg.db_mssql_encrypt);
        assert!(!cfg.db_mssql_trust_cert);
    }

    #[test]
    fn test_db_config_defaults() {
        let config: DatabaseConfig = envy::from_iter(vec![(
            "DATABASE_TARGET".to_string(),
            "postgres".to_string(),
        )])
        .unwrap();
        assert_eq!(config.db_pool_max, 10);
        assert_eq!(config.db_pool_min, 2);
        assert_eq!(config.db_acquire_timeout_secs, 5);
        assert!(!config.db_mssql_encrypt);
        assert!(!config.db_mssql_trust_cert);
    }
    #[test]
    fn test_db_config_defaults_serde() {
        let json_str = r#"{"database_target":"postgres"}"#;
        let config: DatabaseConfig = serde_json::from_str(json_str).unwrap();

        assert_eq!(config.db_pool_max, 10);
        assert_eq!(config.db_pool_min, 2);
        assert_eq!(config.db_acquire_timeout_secs, 5);
        assert!(!config.db_mssql_encrypt);
        assert!(!config.db_mssql_trust_cert);
    }
}
