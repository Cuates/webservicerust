use sqlx::{MySqlPool, Row};
use tokio;

#[tokio::main]
async fn main() {
    let pool = MySqlPool::connect("mysql://root:root@localhost:3306/db").await.unwrap();
    let row = sqlx::query("CALL extractnewsfeed('extractFeed', NULL, NULL, NULL, NULL, NULL, NULL)").fetch_one(&pool).await.unwrap();
    for col in row.columns() {
        println!("COLUMN: {}", sqlx::Column::name(col));
    }
}
