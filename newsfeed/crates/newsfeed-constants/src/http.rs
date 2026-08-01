//! HTTP-related constants: route prefixes, methods, headers,
//! response keys, response statuses, and payload parameter names.

// ── Routing ───────────────────────────────────────────────────────────────────

pub const API_ROUTE_PREFIX: &str = "/api/v1";
pub const PROJECT_NAME: &str = "newsfeed";
pub const HEALTH_LIVE_ROUTE: &str = "/health/live";
pub const HEALTH_READY_ROUTE: &str = "/health/ready";

// ── HTTP header names and expected values ─────────────────────────────────────

pub struct HeaderType;

impl HeaderType {
    pub const CONTENT_TYPE: &'static str = "content-type";
    pub const ACCEPT: &'static str = "accept";
    pub const AUTHORIZATION: &'static str = "authorization";
    pub const API_KEY: &'static str = "x-api-key";
}

pub struct PossibleHeaderType;

impl PossibleHeaderType {
    pub const CONTENT_TYPE: &'static str = "application/json";
    pub const ACCEPT: &'static str = "application/json";
    pub const CHARSET: &'static str = "utf-8";
}

// ── HTTP methods ──────────────────────────────────────────────────────────────

pub struct MethodType;

impl MethodType {
    pub const GET: &'static str = "GET";
    pub const POST: &'static str = "POST";
    pub const PUT: &'static str = "PUT";
    pub const DELETE: &'static str = "DELETE";
    pub const OPTIONS: &'static str = "OPTIONS";
    /// QUERY is defined in IETF draft-ietf-httpbis-safe-method-w-body.
    /// It is implemented but documented as pre-standard pending RFC finalisation.
    pub const QUERY: &'static str = "QUERY";
}

// ── Standard API response field keys ─────────────────────────────────────────

pub struct ResponseKeys;

impl ResponseKeys {
    pub const STATUS: &'static str = "Status";
    pub const MESSAGE: &'static str = "Message";
    pub const COUNT: &'static str = "Count";
    pub const RESULT: &'static str = "Result";
    pub const SERVER_ERROR: &'static str = "SError";
    pub const SERVER_MESSAGE: &'static str = "SMessage";
}

// ── Standard API response status values ──────────────────────────────────────

pub struct ResponseStatus;

impl ResponseStatus {
    pub const SUCCESS: &'static str = "Success";
    pub const ERROR: &'static str = "Error";
}

// ── Standard API response error codes ─────────────────────────────────────────

pub struct ResponseCode;

impl ResponseCode {
    pub const INVALID_HEADER: &'static str = "INVALID_HEADER";
    pub const VALIDATION_ERROR: &'static str = "VALIDATION_ERROR";
    pub const DB_ERROR: &'static str = "DB_ERROR";
    pub const BAD_REQUEST: &'static str = "BAD_REQUEST";
    pub const RATE_LIMIT_EXCEEDED: &'static str = "RATE_LIMIT_EXCEEDED";
    pub const UNAUTHORIZED: &'static str = "UNAUTHORIZED";
    pub const INTERNAL_ERROR: &'static str = "INTERNAL_ERROR";
}

// ── Standard API response messages ───────────────────────────────────────────

pub struct ResponseMessage;

impl ResponseMessage {
    pub const PARTIAL: &'static str = "Partial";
    pub const PAYLOAD_ISSUE: &'static str = "Issue with payload check";
    pub const PROCESSED: &'static str = "Processed request";
    pub const NOT_FOUND: &'static str = "Not Found";
    pub const UNAUTHORIZED: &'static str = "Unauthorized";
    pub const TOO_MANY_REQUESTS: &'static str = "Too Many Requests";
    pub const METHOD_NOT_ALLOWED: &'static str = "Method Not Allowed";
    pub const FAILED_TO_READ_BODY: &'static str = "Failed to read request body";
    pub const TOO_MANY_REQUESTS_RETRY: &'static str =
        "Too many requests. Please wait and try again.";
}

// ── Payload parameter names (lowercase, as normalised from requests) ──────────

pub struct PossiblePayloadParams;

impl PossiblePayloadParams {
    pub const TITLE: &'static str = "title";
    pub const IMAGE_URL: &'static str = "image_url";
    pub const FEED_URL: &'static str = "feed_url";
    pub const ACTUAL_URL: &'static str = "actual_url";
    pub const PUBLISH_DATE: &'static str = "publish_date";
    pub const LIMIT: &'static str = "limit";
    pub const SORT: &'static str = "sort";
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── ResponseCode ─────────────────────────────────────────────────────────

    #[test]
    fn test_response_code_constants() {
        assert_eq!(ResponseCode::INVALID_HEADER, "INVALID_HEADER");
        assert_eq!(ResponseCode::VALIDATION_ERROR, "VALIDATION_ERROR");
        assert_eq!(ResponseCode::DB_ERROR, "DB_ERROR");
        assert_eq!(ResponseCode::BAD_REQUEST, "BAD_REQUEST");
        assert_eq!(ResponseCode::RATE_LIMIT_EXCEEDED, "RATE_LIMIT_EXCEEDED");
        assert_eq!(ResponseCode::UNAUTHORIZED, "UNAUTHORIZED");
        assert_eq!(ResponseCode::INTERNAL_ERROR, "INTERNAL_ERROR");
    }

    // ── ResponseMessage ───────────────────────────────────────────────────────

    #[test]
    fn test_response_message_constants() {
        assert_eq!(ResponseMessage::PARTIAL, "Partial");
        assert_eq!(ResponseMessage::PAYLOAD_ISSUE, "Issue with payload check");
        assert_eq!(ResponseMessage::PROCESSED, "Processed request");
        assert_eq!(ResponseMessage::NOT_FOUND, "Not Found");
        assert_eq!(ResponseMessage::UNAUTHORIZED, "Unauthorized");
        assert_eq!(ResponseMessage::TOO_MANY_REQUESTS, "Too Many Requests");
        assert_eq!(ResponseMessage::METHOD_NOT_ALLOWED, "Method Not Allowed");
        assert_eq!(
            ResponseMessage::FAILED_TO_READ_BODY,
            "Failed to read request body"
        );
        assert_eq!(
            ResponseMessage::TOO_MANY_REQUESTS_RETRY,
            "Too many requests. Please wait and try again."
        );
    }

    // ── ResponseStatus ────────────────────────────────────────────────────────

    #[test]
    fn test_response_status_constants() {
        assert_eq!(ResponseStatus::SUCCESS, "Success");
        assert_eq!(ResponseStatus::ERROR, "Error");
    }

    // ── ResponseKeys ─────────────────────────────────────────────────────────

    #[test]
    fn test_response_keys_constants() {
        assert_eq!(ResponseKeys::STATUS, "Status");
        assert_eq!(ResponseKeys::MESSAGE, "Message");
        assert_eq!(ResponseKeys::COUNT, "Count");
        assert_eq!(ResponseKeys::RESULT, "Result");
        assert_eq!(ResponseKeys::SERVER_ERROR, "SError");
        assert_eq!(ResponseKeys::SERVER_MESSAGE, "SMessage");
    }

    // ── HeaderType / PossibleHeaderType ──────────────────────────────────────

    #[test]
    fn test_header_type_constants() {
        assert_eq!(HeaderType::CONTENT_TYPE, "content-type");
        assert_eq!(HeaderType::ACCEPT, "accept");
        assert_eq!(HeaderType::AUTHORIZATION, "authorization");
        assert_eq!(HeaderType::API_KEY, "x-api-key");
    }

    #[test]
    fn test_possible_header_type_constants() {
        assert_eq!(PossibleHeaderType::CONTENT_TYPE, "application/json");
        assert_eq!(PossibleHeaderType::ACCEPT, "application/json");
        assert_eq!(PossibleHeaderType::CHARSET, "utf-8");
    }

    // ── MethodType ───────────────────────────────────────────────────────────

    #[test]
    fn test_method_type_constants() {
        assert_eq!(MethodType::GET, "GET");
        assert_eq!(MethodType::POST, "POST");
        assert_eq!(MethodType::PUT, "PUT");
        assert_eq!(MethodType::DELETE, "DELETE");
        assert_eq!(MethodType::OPTIONS, "OPTIONS");
        assert_eq!(MethodType::QUERY, "QUERY");
    }

    // ── PossiblePayloadParams ─────────────────────────────────────────────────

    #[test]
    fn test_possible_payload_params_constants() {
        assert_eq!(PossiblePayloadParams::TITLE, "title");
        assert_eq!(PossiblePayloadParams::IMAGE_URL, "image_url");
        assert_eq!(PossiblePayloadParams::FEED_URL, "feed_url");
        assert_eq!(PossiblePayloadParams::ACTUAL_URL, "actual_url");
        assert_eq!(PossiblePayloadParams::PUBLISH_DATE, "publish_date");
        assert_eq!(PossiblePayloadParams::LIMIT, "limit");
        assert_eq!(PossiblePayloadParams::SORT, "sort");
    }
}
