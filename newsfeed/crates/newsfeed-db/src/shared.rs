//! Shared database utilities and helper functions used across backends.

use crate::error::DbError;
use newsfeed_models::NewsFeedRow;

use serde_json::Value;

/// Shared helper to construct a `NewsFeedRow` from mapped Option<String> columns
#[must_use]
pub fn row_to_news_feed_row(
    titlereturn: Option<String>,
    imageurlreturn: Option<String>,
    feedurlreturn: Option<String>,
    actualurlreturn: Option<String>,
    publishdatereturn: Option<String>,
) -> NewsFeedRow {
    NewsFeedRow {
        titlereturn,
        imageurlreturn,
        feedurlreturn,
        actualurlreturn,
        publishdatereturn,
    }
}

pub use newsfeed_models::{CudResult, CudStatus};

/// Parse the status column rows returned by stored procedures.
///
/// A `NULL` status column indicates the procedure produced no usable output —
/// propagated as `DbError::EmptyResult` so the handler returns a 5xx rather
/// than a misleading `200 OK` with an error body.
///
/// Normalizes legacy `"Success"` with `"Record exist"` / `"Record already exists"`
/// or `"does not exist"` messages into `CudStatus::Skipped`.
pub(crate) fn parse_status_rows(rows: Vec<(Option<String>,)>) -> Result<Vec<CudResult>, DbError> {
    let mut results = Vec::new();
    for (status_json,) in rows {
        let json_str = status_json.ok_or(DbError::EmptyResult)?;
        let parsed: Value = serde_json::from_str(&json_str)?;

        let vals = if let Value::Array(arr) = parsed {
            arr
        } else {
            vec![parsed]
        };

        for val in vals {
            let res: CudResult = serde_json::from_value(val)?;
            results.push(res);
        }
    }
    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_status_rows_ok() {
        let rows = vec![(Some(
            r#"{"Status":"Success","Message":"Record inserted"}"#.to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 1);
        assert_eq!(res[0].status, CudStatus::Success);
        assert_eq!(res[0].message, "Record inserted");
    }

    #[test]
    fn test_parse_status_rows_array() {
        let rows = vec![(Some(
            r#"[{"Status":"Success","Message":"ok"},{"Status":"Error","Message":"bad"}]"#
                .to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 2);
        assert_eq!(res[0].status, CudStatus::Success);
        assert_eq!(res[1].status, CudStatus::Error);
    }

    #[test]
    fn test_parse_status_rows_empty_result() {
        let rows = vec![(None,)];
        assert!(parse_status_rows(rows).is_err());
    }

    #[test]
    fn test_parse_status_rows_invalid_json() {
        let rows = vec![(Some("not json".to_string()),)];
        assert!(parse_status_rows(rows).is_err());
    }

    #[test]
    fn test_parse_status_rows_empty_vec() {
        let rows = vec![];
        let res = parse_status_rows(rows).expect("empty vec should return Ok(empty)");
        assert!(res.is_empty());
    }

    #[test]
    fn test_row_to_news_feed_row() {
        use super::row_to_news_feed_row;
        let row = row_to_news_feed_row(
            Some("Title".to_string()),
            Some("Img".to_string()),
            Some("Feed".to_string()),
            Some("Url".to_string()),
            Some("2023-01-01".to_string()),
        );
        assert_eq!(row.titlereturn.as_deref(), Some("Title"));
        assert_eq!(row.imageurlreturn.as_deref(), Some("Img"));
        assert_eq!(row.feedurlreturn.as_deref(), Some("Feed"));
        assert_eq!(row.actualurlreturn.as_deref(), Some("Url"));
        assert_eq!(row.publishdatereturn.as_deref(), Some("2023-01-01"));
    }

    #[test]
    fn test_parse_status_rows_skipped() {
        let rows = vec![(Some(
            r#"{"Status":"Skipped","Message":"Record already exists"}"#.to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 1);
        assert_eq!(res[0].status, CudStatus::Skipped);
        assert_eq!(res[0].message, "Record already exists");
        assert!(res[0].item.is_none());
    }

    #[test]
    fn test_parse_status_rows_with_item() {
        let rows = vec![(Some(
            r#"{"Status":"Error","Message":"Invalid date","Item":{"title":"foo","publish_date":"2026-08-01T12:00:00Z"}}"#.to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 1);
        assert_eq!(res[0].status, CudStatus::Error);
        assert_eq!(res[0].message, "Invalid date");
        let item = res[0].item.as_ref().expect("item should be present");
        assert_eq!(item.title.as_deref().unwrap(), "foo");
        assert_eq!(
            item.publish_date.as_deref().unwrap(),
            "2026-08-01T12:00:00Z"
        );
    }
}
