//! Database-related constants: engine types, procedure names, option modes,
//! server defaults, and pre-compiled regexes for DB-type detection.

use once_cell::sync::Lazy;
use regex::Regex;

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
            Self::MariaDb  => write!(f, "mariadb"),
            Self::MsSql    => write!(f, "mssql"),
        }
    }
}

// ── Stored procedure / function names ─────────────────────────────────────────

/// Stored procedure and function names for each database engine.
pub struct ProcedureMap;

impl ProcedureMap {
    pub const MARIADB_EXTRACT: &'static str  = "extractnewsfeed";
    pub const MARIADB_CUD: &'static str      = "insertupdatedeletenewsfeed";
    pub const POSTGRES_EXTRACT: &'static str = "extractnewsfeed";
    pub const POSTGRES_CUD: &'static str     = "insertupdatedeletenewsfeed";
    pub const MSSQL_EXTRACT: &'static str    = "dbo.extractNewsFeed";
    pub const MSSQL_CUD: &'static str        = "dbo.insertupdatedeleteNewsFeed";
}

// ── Operation modes (passed as the first argument to every procedure) ─────────

/// The `optionMode` value passed to each stored procedure / function.
pub struct OptionMode;

impl OptionMode {
    pub const EXTRACT_FEED: &'static str = "extractNewsFeed";
    pub const INSERT_FEED: &'static str  = "insertNewsFeed";
    pub const UPDATE_FEED: &'static str  = "updateNewsFeed";
    pub const DELETE_FEED: &'static str  = "deleteNewsFeed";
}

// ── Default connection ports ──────────────────────────────────────────────────

pub struct DatabasePort;

impl DatabasePort {
    pub const MARIADB: u16  = 3306;
    pub const POSTGRES: u16 = 5432;
    pub const MSSQL: u16    = 1433;
}

// ── Pre-compiled regex patterns ───────────────────────────────────────────────
// Compiled exactly once at program start via once_cell::Lazy.

/// Matches the MariaDB database type identifier string.
pub static REGEX_MARIADB: Lazy<Regex> =
    Lazy::new(|| Regex::new(r"(?i)mariadb").unwrap());

/// Matches the PostgreSQL database type identifier string.
pub static REGEX_POSTGRES: Lazy<Regex> =
    Lazy::new(|| Regex::new(r"(?i)postgres").unwrap());

/// Matches the MSSQL database type identifier string.
pub static REGEX_MSSQL: Lazy<Regex> =
    Lazy::new(|| Regex::new(r"(?i)mssql").unwrap());
