//! Standalone binary to generate `docs/openapi.json`.
//!
//! Invoke via `cargo make gen-openapi`.
//! The file is safe to commit and import directly into Postman.

use newsfeed_server::openapi::ApiDoc;
use utoipa::OpenApi;

fn main() {
    let spec = match ApiDoc::openapi().to_pretty_json() {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Error: Failed to serialise OpenAPI spec: {e}");
            std::process::exit(1);
        }
    };

    let out_path = "docs/openapi.json";
    if let Err(e) = std::fs::write(out_path, &spec) {
        eprintln!("Error: Failed to write {out_path}: {e}");
        std::process::exit(1);
    }

    println!("[✔] OpenAPI spec written to {out_path}");
}
