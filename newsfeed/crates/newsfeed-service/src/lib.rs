//! newsfeed-service
//!
//! Business logic layer: header/payload validation, query-parameter building,
//! and database operation orchestration.

#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)
)]

pub mod error;
pub mod feed_service;

pub use error::ServiceError;
pub use feed_service::{cud_feed, extract_feed};
pub use newsfeed_db::{CudResult, CudStatus};
