use newsfeed_models::{
    ApiErrorResponse, ApiResponse, CudParams, CudResult, CudStatus, EmptyPayload, ExtractParams,
    NewsFeedRow,
};
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
        schemas(
            ExtractParams, CudParams, NewsFeedRow, CudResult, CudStatus, EmptyPayload,
            ApiResponse<NewsFeedRow>, ApiResponse<CudResult, CudParams>, ApiErrorResponse<EmptyPayload>
        )
    ),
    tags(
        (name = "newsfeed", description = "Newsfeed Management API")
    )
)]
pub struct ApiDoc;
