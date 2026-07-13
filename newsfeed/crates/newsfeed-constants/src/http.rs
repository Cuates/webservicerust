//! HTTP-related constants: route prefixes, methods, headers,
//! response keys, response statuses, and payload parameter names.

// ── Routing ───────────────────────────────────────────────────────────────────

pub const API_ROUTE_PREFIX: &str = "/api";
pub const PROJECT_NAME: &str = "newsfeed";
pub const HEALTH_ROUTE: &str = "/health";

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

// ── Standard API response messages ───────────────────────────────────────────

pub struct ResponseMessage;

impl ResponseMessage {
    pub const PAYLOAD_ISSUE: &'static str = "Issue with payload check";
    pub const PROCESSED: &'static str = "Processed request";
    pub const NOT_FOUND: &'static str = "Not Found";
    pub const UNAUTHORIZED: &'static str = "Unauthorized";
    pub const TOO_MANY_REQUESTS: &'static str = "Too Many Requests";
    pub const METHOD_NOT_ALLOWED: &'static str = "Method Not Allowed";
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
