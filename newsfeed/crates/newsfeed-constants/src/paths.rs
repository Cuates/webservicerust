//! File-system path constants for application resources and logs.
//! Mirrors the Python `PathFilenameConfig` enum.

pub const BASE_NAME: &str = "newsfeedwebservice";

pub struct PathConfig;

impl PathConfig {
    pub const PATH_PARENT: &'static str    = "/usr/local/src/newsfeedwebservice";
    pub const PATH_LEVEL_ONE: &'static str = "resource";
    pub const PATH_LEVEL_TWO: &'static str = "log";

    pub const LOG_FILENAME: &'static str         = "newsfeedwebservice.log";
    pub const DEBUG_LOG: &'static str            = "debug.log";
    pub const INFO_LOG: &'static str             = "info.log";
    pub const ERROR_LOG: &'static str            = "errors.log";
    pub const JSON_ERROR_LOG: &'static str       = "errors_log.json";
    pub const LOGGING_JSON: &'static str         = "logging_dictConfig.json";
}
