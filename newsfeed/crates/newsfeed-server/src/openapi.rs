use newsfeed_models::{ApiResponse, CudParams, ExtractParams, NewsFeedRow};
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::health::live_handler,
        crate::handlers::health::ready_handler,
        crate::handlers::get::handler,
        crate::handlers::cud::post_handler,
        crate::handlers::cud::put_handler,
        crate::handlers::cud::delete_handler
    ),
    components(
        schemas(ExtractParams, CudParams, NewsFeedRow, ApiResponse<serde_json::Value>)
    ),
    tags(
        (name = "newsfeed", description = "Newsfeed Management API")
    )
)]
pub struct ApiDoc;
