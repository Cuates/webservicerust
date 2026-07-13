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
}

impl<E: std::fmt::Debug> From<bb8::RunError<E>> for DbError {
    fn from(e: bb8::RunError<E>) -> Self {
        Self::MssqlPool(format!("{:?}", e))
    }
}
