//! Standard API response envelope used across all endpoints.

use serde::Serialize;

/// Generic API response envelope matching the Python reference format.
///
/// All endpoints return this structure.  Field names use PascalCase in JSON
/// to maintain compatibility with existing clients.
#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    #[serde(rename = "Status")]
    pub status: String,

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
            status:  "Success".to_owned(),
            message: message.into(),
            count,
            result,
        }
    }
}

impl ApiResponse<serde_json::Value> {
    /// Construct an error response with an empty result list.
    pub fn error(message: impl Into<String>) -> Self {
        Self {
            status:  "Error".to_owned(),
            message: message.into(),
            count:   0,
            result:  vec![],
        }
    }
}
