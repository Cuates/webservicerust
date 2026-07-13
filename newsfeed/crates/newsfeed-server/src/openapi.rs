use newsfeed_models::{ApiResponse, CudParams, ExtractParams, NewsFeedRow};
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::health::handler,
        crate::handlers::get::handler,
        crate::handlers::post::handler,
        crate::handlers::put::handler,
        crate::handlers::delete::handler
    ),
    components(
        schemas(ExtractParams, CudParams, NewsFeedRow, ApiResponse<serde_json::Value>)
    ),
    tags(
        (name = "newsfeed", description = "Newsfeed Management API")
    )
)]
pub struct ApiDoc;
