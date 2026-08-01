//! Typed database error variants for the newsfeed-db crate.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("sqlx error: {0}")]
    Sqlx(#[from] sqlx::Error),

    #[error("tiberius error: {0}")]
    Tiberius(#[from] tiberius::error::Error),

    #[error("tiberius TCP error: {0}")]
    TiberiusTcp(#[from] std::io::Error),

    #[error("MSSQL pool error: {0}")]
    MssqlPool(String),

    #[error("JSON parse error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("Database configuration error: {0}")]
    Config(String),

    #[error("Query returned no usable result")]
    EmptyResult,

    #[error("Stored procedure failed: {0}")]
    ProcedureFailed(String),
}

impl<E: std::fmt::Debug> From<bb8::RunError<E>> for DbError {
    fn from(e: bb8::RunError<E>) -> Self {
        Self::MssqlPool(format!("{e:?}"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_db_error_display() {
        let err = DbError::EmptyResult;
        assert_eq!(err.to_string(), "Query returned no usable result");

        let err = DbError::Config("missing host".into());
        assert_eq!(
            err.to_string(),
            "Database configuration error: missing host"
        );

        let err = DbError::ProcedureFailed("bad params".into());
        assert_eq!(err.to_string(), "Stored procedure failed: bad params");

        let err = DbError::MssqlPool("timeout".into());
        assert_eq!(err.to_string(), "MSSQL pool error: timeout");
    }

    #[test]
    fn test_db_error_from_io() {
        let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "not found");
        let err = DbError::from(io_err);
        assert!(err.to_string().starts_with("tiberius TCP error: "));
    }
}
