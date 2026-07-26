//! Shared database utilities and helper functions used across backends.

use crate::error::DbError;
use serde_json::Value;

/// Parse the status column rows returned by stored procedures.
///
/// A `NULL` status column indicates the procedure produced no usable output —
/// propagated as `DbError::EmptyResult` so the handler returns a 5xx rather
/// than a misleading `200 OK` with an error body.
pub(crate) fn parse_status_rows(rows: Vec<(Option<String>,)>) -> Result<Vec<Value>, DbError> {
    let mut results = Vec::new();
    for (status_json,) in rows {
        let json_str = status_json.ok_or(DbError::EmptyResult)?;
        let parsed: Value = serde_json::from_str(&json_str)?;

        if let Value::Array(arr) = parsed {
            results.extend(arr);
        } else {
            results.push(parsed);
        }
    }
    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_status_rows_ok() {
        let rows = vec![(Some(r#"{"Status":"Success"}"#.to_string()),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 1);
        assert_eq!(res[0]["Status"], "Success");
    }

    #[test]
    fn test_parse_status_rows_array() {
        let rows = vec![(Some(
            r#"[{"Status":"Success"},{"Status":"Error"}]"#.to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 2);
        assert_eq!(res[0]["Status"], "Success");
        assert_eq!(res[1]["Status"], "Error");
    }

    #[test]
    fn test_parse_status_rows_empty_result() {
        let rows = vec![(None,)];
        assert!(matches!(parse_status_rows(rows), Err(DbError::EmptyResult)));
    }

    #[test]
    fn test_parse_status_rows_invalid_json() {
        let rows = vec![(Some("not json".to_string()),)];
        assert!(matches!(parse_status_rows(rows), Err(DbError::Json(_))));
    }

    #[test]
    fn test_parse_status_rows_empty_vec() {
        let rows = vec![];
        let res = parse_status_rows(rows).expect("empty vec should return Ok(empty)");
        assert!(res.is_empty());
    }
}
