import os
import pandas as pd
from urllib.parse import quote_plus
from sqlalchemy import create_engine

# Password file mein nahi likhte, terminal se dete hain
pw = quote_plus(os.environ["DB_PASS"])
engine = create_engine(f"mysql+pymysql://root:{pw}@localhost/olist_db")

query = """
SELECT o.order_id,
       DATE(o.order_purchase_timestamp) AS order_date,
       c.customer_unique_id,
       c.customer_city,
       c.customer_state,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       oi.price,
       oi.freight_value,
       r.review_score
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score
           FROM order_reviews GROUP BY order_id) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
"""

df = pd.read_sql(query, engine)

# Region filter ke liye: state ko Brazil ke 5 regions mein baanto
regions = {
    "North": ["AC", "AP", "AM", "PA", "RO", "RR", "TO"],
    "Northeast": ["AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"],
    "Central-West": ["DF", "GO", "MT", "MS"],
    "Southeast": ["ES", "MG", "RJ", "SP"],
    "South": ["PR", "RS", "SC"],
}
state_to_region = {s: r for r, states in regions.items() for s in states}
df["region"] = df["customer_state"].map(state_to_region)

df.to_csv("powerbi/sales_flat.csv", index=False)
print(len(df), "rows saved")
