//! newsfeed-db
//!
//! Async database pool initialisation, `AppState`, and per-engine query
//! executors.  All database I/O is contained in this crate.

#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)
)]

#[cfg(not(any(feature = "postgres", feature = "mariadb", feature = "mssql")))]
compile_error!(
    "At least one database engine feature ('postgres', 'mariadb', 'mssql') must be enabled"
);

pub mod error;
#[cfg(feature = "mariadb")]
pub mod mariadb;
#[cfg(feature = "mssql")]
pub mod mssql;
pub mod pool;
#[cfg(feature = "postgres")]
pub mod postgres;
pub mod shared;

pub use error::DbError;
pub use pool::{AppState, DbPool};
pub use shared::{CudResult, CudStatus};
