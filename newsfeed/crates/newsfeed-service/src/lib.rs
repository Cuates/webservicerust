//! newsfeed-service
//!
//! Business logic layer: header/payload validation, query-parameter building,
//! and database operation orchestration.

pub mod error;
pub mod feed_service;
pub mod payload_validator;

pub use error::ServiceError;
pub use feed_service::{cud_feed, extract_feed};
pub use payload_validator::{validate_headers, validate_payload, ValidatedPayload};
