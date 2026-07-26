//! newsfeed-db
//!
//! Async database pool initialisation, `AppState`, and per-engine query
//! executors.  All database I/O is contained in this crate.

#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)
)]

pub mod error;
pub mod mariadb;
pub mod mssql;
pub mod pool;
pub mod postgres;
pub mod shared;

pub use error::DbError;
pub use pool::{AppState, DbPool};
