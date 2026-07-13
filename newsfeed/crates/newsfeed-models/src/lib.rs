//! newsfeed-models
//!
//! Shared request/response types used across the service and server crates.

pub mod feed;
pub mod response;

pub use feed::{CudParams, ExtractParams, NewsFeedRow};
pub use response::ApiResponse;
