//! newsfeed-db
//!
//! Async database pool initialisation, `AppState`, and per-engine query
//! executors.  All database I/O is contained in this crate.

pub mod error;
pub mod pool;
pub mod postgres;
pub mod mariadb;
pub mod mssql;

pub use error::DbError;
pub use pool::{AppState, DbPool};
