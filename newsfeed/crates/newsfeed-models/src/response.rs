//! Standard API response envelope used across all endpoints.

use serde::Serialize;
use utoipa::ToSchema;

/// Generic API response envelope matching the Python reference format.
///
/// All endpoints return this structure.  Field names use PascalCase in JSON
/// to maintain compatibility with existing clients.
///
/// The `Code` field provides a machine-readable error/success code for clients
/// that need to distinguish error types programmatically.
#[derive(Debug, Serialize, ToSchema)]
pub struct ApiResponse<T: Serialize> {
    #[serde(rename = "Status")]
    pub status: String,

    #[serde(rename = "Code")]
    pub code: String,

    #[serde(rename = "Message")]
    pub message: String,

    #[serde(rename = "Count")]
    pub count: usize,

    #[serde(rename = "Result")]
    pub result: Vec<T>,
}

impl<T: Serialize> ApiResponse<T> {
    /// Construct a success response.
    pub fn success(message: impl Into<String>, result: Vec<T>) -> Self {
        let count = result.len();
        Self {
            status: "Success".to_owned(),
            code: "OK".to_owned(),
            message: message.into(),
            count,
            result,
        }
    }

    /// Construct an error response with an empty result list.
    ///
    /// Works for any `T: Serialize`, eliminating the need to specify
    /// `ApiResponse::<serde_json::Value>::error(...)` at every call site.
    pub fn error(message: impl Into<String>) -> ApiResponse<serde_json::Value> {
        ApiResponse {
            status: "Error".to_owned(),
            code: "ERROR".to_owned(),
            message: message.into(),
            count: 0,
            result: vec![],
        }
    }

    /// Construct an error response with a specific machine-readable code.
    pub fn error_with_code(
        code: impl Into<String>,
        message: impl Into<String>,
    ) -> ApiResponse<serde_json::Value> {
        ApiResponse {
            status: "Error".to_owned(),
            code: code.into(),
            message: message.into(),
            count: 0,
            result: vec![],
        }
    }
}
