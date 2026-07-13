//! Database-related constants: engine types, procedure names, option modes,
//! and server defaults.

// ── Database engine type ──────────────────────────────────────────────────────

/// Identifies which database engine to target.
/// Deserialised from the `DATABASE_TARGET` environment variable.
#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DatabaseType {
    Postgres,
    MariaDb,
    MsSql,
}

impl std::fmt::Display for DatabaseType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Postgres => write!(f, "postgres"),
            Self::MariaDb => write!(f, "mariadb"),
            Self::MsSql => write!(f, "mssql"),
        }
    }
}

// ── Stored procedure / function names ─────────────────────────────────────────

/// Stored procedure and function names for each database engine.
pub struct ProcedureMap;

impl ProcedureMap {
    pub const MARIADB_EXTRACT: &'static str = "extractnewsfeed";
    pub const MARIADB_CUD: &'static str = "insertupdatedeletenewsfeed";
    pub const POSTGRES_EXTRACT: &'static str = "extractnewsfeed";
    pub const POSTGRES_CUD: &'static str = "insertupdatedeletenewsfeed";
    pub const MSSQL_EXTRACT: &'static str = "dbo.extractNewsFeed";
    pub const MSSQL_CUD: &'static str = "dbo.insertupdatedeleteNewsFeed";
}

// ── Operation modes (passed as the first argument to every procedure) ─────────

/// The `optionMode` value passed to each stored procedure / function.
///
/// Using an enum instead of bare `&str` constants gives compile-time safety:
/// a typo in an `OptionMode` variant is a compiler error, not a silent
/// runtime failure in the stored procedure.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OptionMode {
    ExtractFeed,
    InsertFeed,
    UpdateFeed,
    DeleteFeed,
}

impl OptionMode {
    /// Return the exact `optionMode` string expected by the stored procedures.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::ExtractFeed => "extractNewsFeed",
            Self::InsertFeed => "insertNewsFeed",
            Self::UpdateFeed => "updateNewsFeed",
            Self::DeleteFeed => "deleteNewsFeed",
        }
    }
}

// ── Default connection ports ──────────────────────────────────────────────────

pub struct DatabasePort;

impl DatabasePort {
    pub const MARIADB: u16 = 3306;
    pub const POSTGRES: u16 = 5432;
    pub const MSSQL: u16 = 1433;
}
