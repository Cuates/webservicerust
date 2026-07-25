use axum::extract::ConnectInfo;
use axum::http::Request;
use std::net::{IpAddr, SocketAddr};
use tower_governor::GovernorError;
use tower_governor::key_extractor::KeyExtractor;

#[derive(Clone)]
pub struct SecureIpExtractor {
    pub trust_proxy: bool,
    pub trusted_cidrs: Vec<ipnet::IpNet>,
}

impl SecureIpExtractor {
    #[must_use]
    pub fn new(trust_proxy: bool, trusted_cidrs: Vec<ipnet::IpNet>) -> Self {
        Self {
            trust_proxy,
            trusted_cidrs,
        }
    }
}

impl KeyExtractor for SecureIpExtractor {
    type Key = IpAddr;

    fn extract<T>(&self, req: &Request<T>) -> Result<Self::Key, GovernorError> {
        let peer_ip = req
            .extensions()
            .get::<ConnectInfo<SocketAddr>>()
            .map_or_else(
                || std::net::IpAddr::V4(std::net::Ipv4Addr::LOCALHOST),
                |c| c.0.ip(),
            );

        if !self.trust_proxy {
            return Ok(peer_ip);
        }

        let is_trusted = self
            .trusted_cidrs
            .iter()
            .any(|cidr| cidr.contains(&peer_ip));
        if !is_trusted {
            return Ok(peer_ip);
        }

        if let Some(forwarded) = req.headers().get("x-forwarded-for")
            && let Ok(forwarded_str) = forwarded.to_str()
            && let Some(first_ip) = forwarded_str.split(',').next()
            && let Ok(ip) = first_ip.trim().parse::<IpAddr>()
        {
            return Ok(ip);
        }

        if let Some(real_ip) = req.headers().get("x-real-ip")
            && let Ok(real_ip_str) = real_ip.to_str()
            && let Ok(ip) = real_ip_str.parse::<IpAddr>()
        {
            return Ok(ip);
        }

        Ok(peer_ip)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::Request;

    #[test]
    fn test_secure_ip_extractor_no_trust_proxy() {
        let extractor = SecureIpExtractor::new(false, vec![]);
        let req = Request::builder().body(()).unwrap();
        let ip = extractor.extract(&req).unwrap();
        assert_eq!(ip, std::net::IpAddr::V4(std::net::Ipv4Addr::LOCALHOST));
    }

    #[test]
    fn test_secure_ip_extractor_trust_proxy_not_trusted_cidr() {
        let cidr = "192.168.0.0/24".parse().unwrap();
        let extractor = SecureIpExtractor::new(true, vec![cidr]);
        let mut req = Request::builder().body(()).unwrap();
        req.extensions_mut().insert(ConnectInfo(SocketAddr::new(
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1)),
            8080,
        )));
        let ip = extractor.extract(&req).unwrap();
        assert_eq!(
            ip,
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1))
        );
    }

    #[test]
    fn test_secure_ip_extractor_x_forwarded_for() {
        let cidr = "10.0.0.0/8".parse().unwrap();
        let extractor = SecureIpExtractor::new(true, vec![cidr]);
        let mut req = Request::builder()
            .header("x-forwarded-for", "203.0.113.195, 70.41.3.18")
            .body(())
            .unwrap();
        req.extensions_mut().insert(ConnectInfo(SocketAddr::new(
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1)),
            8080,
        )));
        let ip = extractor.extract(&req).unwrap();
        assert_eq!(
            ip,
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(203, 0, 113, 195))
        );
    }

    #[test]
    fn test_secure_ip_extractor_x_real_ip() {
        let cidr = "10.0.0.0/8".parse().unwrap();
        let extractor = SecureIpExtractor::new(true, vec![cidr]);
        let mut req = Request::builder()
            .header("x-real-ip", "203.0.113.195")
            .body(())
            .unwrap();
        req.extensions_mut().insert(ConnectInfo(SocketAddr::new(
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1)),
            8080,
        )));
        let ip = extractor.extract(&req).unwrap();
        assert_eq!(
            ip,
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(203, 0, 113, 195))
        );
    }

    #[test]
    fn test_secure_ip_extractor_fallback() {
        let cidr = "10.0.0.0/8".parse().unwrap();
        let extractor = SecureIpExtractor::new(true, vec![cidr]);
        let mut req = Request::builder().body(()).unwrap();
        req.extensions_mut().insert(ConnectInfo(SocketAddr::new(
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1)),
            8080,
        )));
        let ip = extractor.extract(&req).unwrap();
        assert_eq!(
            ip,
            std::net::IpAddr::V4(std::net::Ipv4Addr::new(10, 0, 0, 1))
        );
    }
}
