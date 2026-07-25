use axum::{
    Json,
    extract::{FromRequest, Request, rejection::JsonRejection},
    http::StatusCode,
    response::{IntoResponse, Response},
};
use newsfeed_constants::http::ResponseCode;
use newsfeed_models::ApiResponse;

/// A custom JSON extractor that wraps axum's `Json` extractor.
/// It catches `JsonRejection`s and converts them into our standard `ApiResponse` JSON.
pub struct AppJson<T>(pub T);

impl<T, S> FromRequest<S> for AppJson<T>
where
    Json<T>: FromRequest<S, Rejection = JsonRejection>,
    S: Send + Sync,
{
    type Rejection = Response;

    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        match Json::<T>::from_request(req, state).await {
            Ok(value) => Ok(Self(value.0)),
            Err(rejection) => {
                let (status, code) = match rejection {
                    JsonRejection::MissingJsonContentType(_) => (
                        StatusCode::UNSUPPORTED_MEDIA_TYPE,
                        ResponseCode::INVALID_HEADER,
                    ),
                    _ => (StatusCode::BAD_REQUEST, ResponseCode::BAD_REQUEST),
                };
                let body_text = rejection.body_text();
                let payload = ApiResponse::<serde_json::Value>::error_with_code(code, &body_text);
                Err((status, Json(payload)).into_response())
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Router, http::StatusCode, routing::post};
    use axum_test::TestServer;

    async fn dummy_handler(_body: AppJson<serde_json::Value>) -> &'static str {
        "ok"
    }

    #[tokio::test]
    async fn test_app_json_missing_content_type() {
        let app = Router::new().route("/", post(dummy_handler));
        let server = TestServer::new(app);
        let res = server.post("/").text("{\"a\":1}").await;
        assert_eq!(res.status_code(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
        let body: serde_json::Value = res.json();
        assert_eq!(body["Code"], "INVALID_HEADER");
    }

    #[tokio::test]
    async fn test_app_json_invalid_syntax() {
        let app = Router::new().route("/", post(dummy_handler));
        let server = TestServer::new(app);
        let res = server
            .post("/")
            .add_header(
                axum::http::header::CONTENT_TYPE,
                axum::http::header::HeaderValue::from_static("application/json"),
            )
            .bytes(axum::body::Bytes::from(b"{invalid}".to_vec()))
            .await;
        assert_eq!(res.status_code(), StatusCode::BAD_REQUEST);
        let body: serde_json::Value = res.json();
        assert_eq!(body["Code"], "BAD_REQUEST");
    }

    #[tokio::test]
    async fn test_app_json_valid() {
        let app = Router::new().route("/", post(dummy_handler));
        let server = TestServer::new(app);
        let res = server
            .post("/")
            .add_header(
                axum::http::header::CONTENT_TYPE,
                axum::http::header::HeaderValue::from_static("application/json"),
            )
            .bytes(axum::body::Bytes::from(b"{\"valid\": true}".to_vec()))
            .await;
        assert_eq!(res.status_code(), StatusCode::OK);
        assert_eq!(res.text(), "ok");
    }
}
