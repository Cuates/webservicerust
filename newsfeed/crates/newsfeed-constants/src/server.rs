pub struct Timeouts;

impl Timeouts {
    pub const HEALTH_CHECK_SECS: u64 = 10;
    pub const SHUTDOWN_SECS: u64 = 1;
    pub const SLEEP_MS: u64 = 10;
}
