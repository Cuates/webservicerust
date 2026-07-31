#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)
)]

pub mod extractors;
pub mod handlers;
pub mod middleware;
pub mod openapi;
pub mod router;
pub mod shutdown;
pub mod validation;
