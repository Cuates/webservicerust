use axum::{
    extract::{rejection::JsonRejection, FromRequest, Request},
    response::{IntoResponse, Response},
    Json,
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
                let status = rejection.status();
                let body_text = rejection.body_text();
                let payload = ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::BAD_REQUEST,
                    &body_text,
                );
                Err((status, Json(payload)).into_response())
            }
        }
    }
}
