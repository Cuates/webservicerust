//! Request header and CUD parameter validation for the server layer.

use axum::http::HeaderMap;
use newsfeed_constants::http::{HeaderType, PossibleHeaderType, ResponseCode};
use newsfeed_models::{ApiResponse, CudParams};
use newsfeed_service::ServiceError;

pub use newsfeed_constants::db::OptionMode as Action;

/// Validate request headers against expected values.
///
/// `requires_body` — when `true` (POST / PUT / DELETE), enforces the presence
/// of `Content-Type: application/json; charset=utf-8`. When `false` (GET /
/// QUERY), only the `Accept` header is checked, since bodyless requests do not
/// carry a `Content-Type` by RFC convention.
pub fn validate_headers(headers: &HeaderMap, requires_body: bool) -> Result<(), ServiceError> {
    let accept = headers
        .get(HeaderType::ACCEPT)
        .and_then(|h| h.to_str().ok())
        .unwrap_or_default()
        .to_lowercase();

    if accept != PossibleHeaderType::ACCEPT {
        return Err(ServiceError::InvalidHeader("HTTP accept invalid".into()));
    }

    if requires_body {
        let raw_ct = headers
            .get(HeaderType::CONTENT_TYPE)
            .and_then(|h| h.to_str().ok())
            .unwrap_or_default()
            .to_lowercase();

        // Split "application/json; charset=utf-8" into content-type and charset parts.
        let mut parts = raw_ct.splitn(2, ';');
        let content_type = parts.next().unwrap_or("").trim().to_owned();
        let charset = parts
            .next()
            .and_then(|p| p.split('=').nth(1))
            .map(|s| s.trim().to_owned())
            .unwrap_or_default();

        if content_type != PossibleHeaderType::CONTENT_TYPE {
            return Err(ServiceError::UnsupportedContentType(
                "Content type invalid".into(),
            ));
        }
        if charset != PossibleHeaderType::CHARSET {
            return Err(ServiceError::UnsupportedContentType(
                "Content-Type charset invalid".into(),
            ));
        }
    }

    Ok(())
}

/// Validate required fields on a `CudParams` object depending on the CUD action.
#[allow(clippy::result_large_err)]
pub fn validate_required_fields(
    params: &CudParams,
    action: &Action,
) -> Result<(), ApiResponse<serde_json::Value>> {
    match action {
        Action::InsertFeed | Action::DeleteFeed => {
            if params.title.is_none() {
                return Err(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::VALIDATION_ERROR,
                    "Missing mandatory parameter: title",
                ));
            }
        }
        Action::UpdateFeed => {
            if params.title.is_none() {
                return Err(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::VALIDATION_ERROR,
                    "Missing mandatory parameter: title",
                ));
            }
            if params.publish_date.is_none() {
                return Err(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::VALIDATION_ERROR,
                    "Missing mandatory parameter: publish_date",
                ));
            }
        }
        Action::ExtractFeed => {}
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;

    #[test]
    fn test_validate_headers_requires_body_success() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE,
            HeaderValue::from_static("application/json; charset=utf-8"),
        );
        assert!(validate_headers(&headers, true).is_ok());
    }

    #[test]
    fn test_validate_headers_requires_body_missing_content_type() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );

        let result = validate_headers(&headers, true);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_requires_body_invalid_charset() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE,
            HeaderValue::from_static("application/json; charset=utf-16"),
        );
        let result = validate_headers(&headers, true);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_requires_body_missing_charset_value() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE,
            HeaderValue::from_static("application/json; charset"),
        );
        let result = validate_headers(&headers, true);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_requires_body_no_semicolon() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE,
            HeaderValue::from_static("application/json"),
        );
        let result = validate_headers(&headers, true);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_no_body_success() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );

        assert!(validate_headers(&headers, false).is_ok());
    }

    #[test]
    fn test_validate_headers_invalid_accept() {
        let mut headers = HeaderMap::new();
        headers.insert(HeaderType::ACCEPT, HeaderValue::from_static("text/html"));

        let result = validate_headers(&headers, false);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_missing_accept() {
        let headers = HeaderMap::new();
        let result = validate_headers(&headers, false);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_headers_invalid_content_type() {
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderType::ACCEPT,
            HeaderValue::from_static(PossibleHeaderType::ACCEPT),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE,
            HeaderValue::from_static("text/plain; charset=utf-8"),
        );
        let result = validate_headers(&headers, true);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_required_fields_insert() {
        let mut params = CudParams::default();
        assert!(validate_required_fields(&params, &Action::InsertFeed).is_err());

        params.title = Some("Test Title".to_string());
        assert!(validate_required_fields(&params, &Action::InsertFeed).is_ok());
    }

    #[test]
    fn test_validate_required_fields_update() {
        let mut params = CudParams::default();
        assert!(validate_required_fields(&params, &Action::UpdateFeed).is_err());

        params.title = Some("Test Title".to_string());
        assert!(validate_required_fields(&params, &Action::UpdateFeed).is_err());

        params.publish_date = Some("2026-07-26".to_string());
        assert!(validate_required_fields(&params, &Action::UpdateFeed).is_ok());
    }

    #[test]
    fn test_validate_required_fields_delete() {
        let mut params = CudParams::default();
        assert!(validate_required_fields(&params, &Action::DeleteFeed).is_err());

        params.title = Some("Test Title".to_string());
        // For delete, only title is required
        assert!(validate_required_fields(&params, &Action::DeleteFeed).is_ok());
    }

    #[test]
    fn test_validate_required_fields_extract() {
        let params = CudParams::default();
        assert!(validate_required_fields(&params, &Action::ExtractFeed).is_ok());
    }
}
