//! Typed service-layer errors.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum ServiceError {
    #[error("Invalid header: {0}")]
    InvalidHeader(String),

    #[error("Invalid payload: {0}")]
    InvalidPayload(String),

    #[error("Missing mandatory parameter: {0}")]
    MissingMandatoryParam(String),

    #[error("Database error: {0}")]
    Database(#[from] newsfeed_db::DbError),
}
