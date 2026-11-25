USE olist_db;

SELECT ROUND(SUM(oi.price),2) AS total_revenue, COUNT(DISTINCT o.order_id) AS orders
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

WITH c AS (
  SELECT cu.customer_unique_id, COUNT(DISTINCT o.order_id) AS n
  FROM customers cu JOIN orders o ON cu.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY cu.customer_unique_id)
SELECT COUNT(*) AS total_customers, SUM(n > 1) AS repeat_customers,
       ROUND(SUM(n > 1) / COUNT(*) * 100, 2) AS repeat_rate_pct
FROM c;

SELECT CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'on_time' ELSE 'late' END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       ROUND(SUM(oi.price),2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category ORDER BY revenue DESC LIMIT 5;

SELECT c.customer_state, ROUND(SUM(oi.price),2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state ORDER BY revenue DESC LIMIT 5;

SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;

SELECT ROUND(AVG(review_score),2) AS avg_review FROM order_reviews;
