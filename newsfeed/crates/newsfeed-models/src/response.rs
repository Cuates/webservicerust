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

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_success_response_shape() {
        let items = vec![json!({"title": "Hello"})];
        let resp = ApiResponse::success("All good", items);

        let serialized = serde_json::to_value(&resp).unwrap();
        assert_eq!(serialized["Status"], "Success");
        assert_eq!(serialized["Code"], "OK");
        assert_eq!(serialized["Message"], "All good");
        assert_eq!(serialized["Count"], 1);
        assert_eq!(serialized["Result"][0]["title"], "Hello");
    }

    #[test]
    fn test_success_response_count_matches_result_len() {
        let items: Vec<serde_json::Value> = vec![json!({}), json!({}), json!({})];
        let resp = ApiResponse::success("ok", items);
        assert_eq!(resp.count, 3);
    }

    #[test]
    fn test_error_response_shape() {
        let resp = ApiResponse::<serde_json::Value>::error("something went wrong");
        let serialized = serde_json::to_value(&resp).unwrap();
        assert_eq!(serialized["Status"], "Error");
        assert_eq!(serialized["Code"], "ERROR");
        assert_eq!(serialized["Message"], "something went wrong");
        assert_eq!(serialized["Count"], 0);
        assert!(serialized["Result"].as_array().unwrap().is_empty());
    }

    #[test]
    fn test_error_with_code_response_shape() {
        let resp = ApiResponse::<serde_json::Value>::error_with_code(
            "VALIDATION_ERROR",
            "title is required",
        );
        let serialized = serde_json::to_value(&resp).unwrap();
        assert_eq!(serialized["Status"], "Error");
        assert_eq!(serialized["Code"], "VALIDATION_ERROR");
        assert_eq!(serialized["Message"], "title is required");
        assert_eq!(serialized["Count"], 0);
    }
}
