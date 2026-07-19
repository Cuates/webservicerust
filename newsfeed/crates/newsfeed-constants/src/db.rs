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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_option_mode_as_str() {
        assert_eq!(OptionMode::ExtractFeed.as_str(), "extractNewsFeed");
        assert_eq!(OptionMode::InsertFeed.as_str(), "insertNewsFeed");
        assert_eq!(OptionMode::UpdateFeed.as_str(), "updateNewsFeed");
        assert_eq!(OptionMode::DeleteFeed.as_str(), "deleteNewsFeed");
    }

    #[test]
    fn test_database_type_display() {
        assert_eq!(DatabaseType::Postgres.to_string(), "postgres");
        assert_eq!(DatabaseType::MariaDb.to_string(), "mariadb");
        assert_eq!(DatabaseType::MsSql.to_string(), "mssql");
    }

    #[test]
    fn test_database_port_constants() {
        assert_eq!(DatabasePort::MARIADB, 3306);
        assert_eq!(DatabasePort::POSTGRES, 5432);
        assert_eq!(DatabasePort::MSSQL, 1433);
    }

    #[test]
    fn test_procedure_map_constants() {
        assert_eq!(ProcedureMap::MARIADB_EXTRACT, "extractnewsfeed");
        assert_eq!(ProcedureMap::POSTGRES_CUD, "insertupdatedeletenewsfeed");
        assert_eq!(ProcedureMap::MSSQL_EXTRACT, "dbo.extractNewsFeed");
        assert_eq!(ProcedureMap::MSSQL_CUD, "dbo.insertupdatedeleteNewsFeed");
    }
}
