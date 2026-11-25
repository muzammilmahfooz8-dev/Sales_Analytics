import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine("mysql+pymysql://root:Root%40123@localhost:3306/olist_db")

files = [
    ("olist_customers_dataset.csv", "customers", []),
    ("olist_sellers_dataset.csv", "sellers", []),
    ("olist_products_dataset.csv", "products", []),
    ("product_category_name_translation.csv", "category_translation", []),
    ("olist_geolocation_dataset.csv", "geolocation", []),
    ("olist_orders_dataset.csv", "orders", [
        "order_purchase_timestamp", "order_approved_at",
        "order_delivered_carrier_date", "order_delivered_customer_date",
        "order_estimated_delivery_date"]),
    ("olist_order_items_dataset.csv", "order_items", ["shipping_limit_date"]),
    ("olist_order_payments_dataset.csv", "order_payments", []),
    ("olist_order_reviews_dataset.csv", "order_reviews", [
        "review_creation_date", "review_answer_timestamp"]),
]

for csv, table, date_cols in files:
    df = pd.read_csv("data/" + csv)

    if table == "products":
        df = df.rename(columns={
            "product_name_lenght": "product_name_length",
            "product_description_lenght": "product_description_length"})

    for c in date_cols:
        df[c] = pd.to_datetime(df[c])

    df = df.astype(object).where(df.notnull(), None)

    with engine.begin() as conn:
        conn.execute(text(f"DELETE FROM {table}"))

    df.to_sql(table, engine, if_exists="append", index=False, chunksize=10000)
    print(table, len(df), "rows loaded")

print("Sab ho gaya!")