USE olist_db;

-- Q1: Har order status ke kitne orders (GROUP BY)
SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Q2: Top 5 states by customers (GROUP BY)
SELECT customer_state, COUNT(*) AS customers
FROM customers
GROUP BY customer_state
ORDER BY customers DESC
LIMIT 5;

-- Q3: 2018 ke delivered orders (FILTER)
SELECT COUNT(*) AS delivered_2018
FROM orders
WHERE order_status = 'delivered'
  AND YEAR(order_purchase_timestamp) = 2018;

-- Q4: 500 se badi payments, payment type ke hisab se (FILTER + GROUP BY)
SELECT payment_type, COUNT(*) AS big_payments
FROM order_payments
WHERE payment_value > 500
GROUP BY payment_type
ORDER BY big_payments DESC;

-- Q5: Payment type ke hisab se total value (GROUP BY)
SELECT payment_type, COUNT(*) AS payments, ROUND(SUM(payment_value), 2) AS total_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_value DESC;

-- Q6: Average review score (AGGREGATE)
SELECT ROUND(AVG(review_score), 2) AS avg_score, COUNT(*) AS total_reviews
FROM order_reviews;

-- Q7: Delivered orders ka total revenue (JOIN)
SELECT ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Q8: Top 10 states by revenue (JOIN: customers + orders + order_items)
SELECT c.customer_state, ROUND(SUM(oi.price), 2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;

-- Q9: Top 10 categories by revenue (JOIN + COALESCE for NULL category)
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- Q10: Average delivery days (NULL dates ko ignore karte hain)
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
