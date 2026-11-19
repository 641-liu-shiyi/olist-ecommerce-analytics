
USE olist_ecommerce;

-- 1. Customer Data Quality
-- Check missing customer identifiers and locations.

SELECT
    COUNT(*) AS total_customer_records,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_ids,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_cities,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_states
FROM customers;


-- 2. Order and Payment Completeness
-- Identify orders without matching payment records.

SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT p.order_id) AS orders_with_payments,
    COUNT(DISTINCT o.order_id)
        - COUNT(DISTINCT p.order_id)
        AS orders_without_payments
FROM orders o
LEFT JOIN order_payments p
    ON o.order_id = p.order_id;


-- 3. Inspect Orders Without Payment Records
-- Investigate exceptions instead of assuming their cause.

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date
FROM orders o
LEFT JOIN order_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;


-- 4. Duplicate Order ID Check
-- Order IDs should be unique in the orders table.

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 5. Missing Delivery Timestamps
-- Examine missing dates among delivered orders.

SELECT
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NULL
        THEN 1 ELSE 0 END) AS missing_actual_delivery_dates,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL
        THEN 1 ELSE 0 END) AS missing_estimated_delivery_dates
FROM orders
WHERE order_status = 'delivered';
