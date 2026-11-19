
-- View 1: Monthly Sales Performance
-- Aggregates monthly order counts, payments, and average order value.
-- Analysis period: January 2017 to August 2018.

CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(
        SUM(p.payment_value) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS avg_order_value
FROM orders o
JOIN order_payments p
    ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');



-- View 2: Product Category Sales Analysis
-- Summarizes items sold, total sales, and average item price
-- for each product category.

CREATE OR REPLACE VIEW vw_category_sales AS
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    COUNT(*) AS total_items_sold,

    ROUND(SUM(oi.price), 2) AS total_sales,

    ROUND(AVG(oi.price), 2) AS avg_item_price

FROM order_items oi

LEFT JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

GROUP BY category;



-- View 3: State-Level Sales Analysis
-- Analyzes customer counts, order volumes, payments,
-- and average order value across Brazilian states.

CREATE OR REPLACE VIEW vw_state_sales AS
SELECT
    c.customer_state AS customer_state,

    COUNT(DISTINCT c.customer_unique_id) AS total_customers,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(SUM(p.payment_value), 2) AS total_payment_value,

    ROUND(
        SUM(p.payment_value) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS avg_order_value

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_payments p
    ON o.order_id = p.order_id

WHERE c.customer_state IS NOT NULL

GROUP BY c.customer_state;



-- View 4: Delivery Performance Analysis
-- Calculates delivery volume, late deliveries,
-- late delivery percentage, and average delivery time.

CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT
    COUNT(*) AS total_delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_pct,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                order_purchase_timestamp,
                order_delivered_customer_date
            )
        ) / 24.0,
        2
    ) AS avg_delivery_days

FROM orders

WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
