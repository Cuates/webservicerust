//! Shared database utilities and helper functions used across backends.

use crate::error::DbError;
use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Status of a CUD operation returned by the database.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub enum CudStatus {
    Success,
    Skipped,
    Error,
}

/// Result of a CUD operation for a single item in a batch.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct CudResult {
    pub status: CudStatus,
    #[serde(default)]
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub item: Option<Value>,
}

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
            let mut res: CudResult = serde_json::from_value(val)?;
            if res.status == CudStatus::Success {
                let msg_lower = res.message.to_lowercase();
                if msg_lower.contains("exist")
                    || msg_lower.contains("already exists")
                    || msg_lower.contains("does not exist")
                {
                    res.status = CudStatus::Skipped;
                }
            }
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
    fn test_parse_status_rows_normalization() {
        let rows = vec![(Some(
            r#"[{"Status":"Success","Message":"Record exist"},{"Status":"Success","Message":"Record already exists"},{"Status":"Skipped","Message":"Record already exists"}]"#
                .to_string(),
        ),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 3);
        assert_eq!(res[0].status, CudStatus::Skipped);
        assert_eq!(res[1].status, CudStatus::Skipped);
        assert_eq!(res[2].status, CudStatus::Skipped);
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
}
