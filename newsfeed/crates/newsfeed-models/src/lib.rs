//! newsfeed-models
//!
//! Shared request/response types used across the service and server crates.

pub mod feed;
pub mod response;

pub use feed::{
    ExtractParams, CudParams, NewsFeedRow, CudRow,
};
pub use response::ApiResponse;
