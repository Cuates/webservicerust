//! newsfeed-service
//!
//! Business logic layer: header/payload validation, query-parameter building,
//! and database operation orchestration.

pub mod error;
pub mod payload_validator;
pub mod feed_service;

pub use error::ServiceError;
pub use feed_service::{extract_feed, cud_feed};
pub use payload_validator::{validate_headers, validate_payload, ValidatedPayload};
