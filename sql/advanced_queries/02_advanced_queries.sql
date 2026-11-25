USE olist_db;

-- Q1: Monthly revenue + running total (CTE + window SUM OVER)
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
           ROUND(SUM(oi.price), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY ym
)
SELECT ym, revenue,
       ROUND(SUM(revenue) OVER (ORDER BY ym), 2) AS running_total
FROM monthly
ORDER BY ym;

-- Q2: Month-on-month growth % (CTE + LAG window function)
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
           SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY ym
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY ym), 2) AS prev_month,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
             / LAG(revenue) OVER (ORDER BY ym) * 100, 1) AS mom_growth_pct
FROM monthly
ORDER BY ym;

-- Q3: Top 10 categories ranked by revenue (CTE + RANK)
WITH cat AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS rnk,
       category,
       ROUND(revenue, 2) AS revenue
FROM cat
ORDER BY rnk
LIMIT 10;

-- Q4: Top 10 customers by spend (customer_unique_id = asli customer)
WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(oi.price) AS spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT RANK() OVER (ORDER BY spend DESC) AS rnk,
       customer_unique_id, orders,
       ROUND(spend, 2) AS total_spend
FROM cust
ORDER BY rnk
LIMIT 10;

-- Q5: Repeat-purchase rate (kitne customers ne 1 se zyada baar kharida)
WITH cust_orders AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS n_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS total_customers,
       SUM(n_orders > 1) AS repeat_customers,
       ROUND(SUM(n_orders > 1) / COUNT(*) * 100, 2) AS repeat_rate_pct
FROM cust_orders;

-- Q6: Category margin proxy (dataset mein product cost nahi hai,
-- isliye price minus freight ko margin ka proxy maana hai)
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(*) AS items_sold,
       ROUND(SUM(oi.price), 2) AS revenue,
       ROUND(SUM(oi.price - oi.freight_value), 2) AS net_after_freight,
       ROUND(SUM(oi.price - oi.freight_value) / SUM(oi.price) * 100, 1) AS margin_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
HAVING COUNT(*) >= 500
ORDER BY margin_pct DESC
LIMIT 10;

-- Q7: Har state ki top 3 categories (CTE + ROW_NUMBER + PARTITION BY)
WITH state_cat AS (
    SELECT c.customer_state AS state,
           COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY state, category
),
ranked AS (
    SELECT state, category, revenue,
           ROW_NUMBER() OVER (PARTITION BY state ORDER BY revenue DESC) AS rn
    FROM state_cat
)
SELECT state, rn, category, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rn <= 3 AND state IN ('SP', 'RJ', 'MG')
ORDER BY state, rn;

-- Q8: On-time vs late delivery % (CASE + window SUM OVER)
SELECT CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'on_time' ELSE 'late' END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- Q9: Top 10 sellers by revenue (CTE + RANK)
WITH seller_rev AS (
    SELECT oi.seller_id, s.seller_state,
           SUM(oi.price) AS revenue,
           COUNT(DISTINCT oi.order_id) AS orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, s.seller_state
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS rnk,
       seller_id, seller_state, orders,
       ROUND(revenue, 2) AS revenue
FROM seller_rev
ORDER BY rnk
LIMIT 10;
