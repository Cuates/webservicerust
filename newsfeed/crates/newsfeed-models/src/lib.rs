//! newsfeed-models
//!
//! Shared request/response types used across the service and server crates.

#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)
)]

pub mod feed;
pub mod response;

pub use feed::{CudParams, ExtractParams, NewsFeedRow, SortOrder};
pub use response::{ApiResponse, FailedItem};
