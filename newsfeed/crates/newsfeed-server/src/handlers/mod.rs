//! HTTP request handlers.
pub mod health;
pub mod get;
pub mod post;
pub mod put;
pub mod delete;
pub mod query;
pub mod not_found;

// Shared handler helper: extract lowercase header map from Axum HeaderMap.
pub(crate) fn header_map_to_lowercase(
    headers: &axum::http::HeaderMap,
) -> std::collections::HashMap<String, String> {
    headers
        .iter()
        .filter_map(|(k, v)| {
            v.to_str()
                .ok()
                .map(|val| (k.as_str().to_lowercase(), val.to_lowercase()))
        })
        .collect()
}
