-- Olist E-commerce Analytics
-- SQL Analysis
-- Database: Olist Brazilian E-commerce Public Dataset

-- ============================================================
-- 1. TOTAL CUSTOMERS WITH ORDERS
-- ============================================================

SELECT COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id;


-- ============================================================
-- 2. CUSTOMER ORDER FREQUENCY
-- Identify customers who placed more than one order
-- ============================================================

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;


-- ============================================================
-- 3. REPEAT CUSTOMER RATE
-- ============================================================

SELECT
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(CASE WHEN total_orders = 1 THEN 1 END) AS one_time_customers,
    ROUND(
        COUNT(CASE WHEN total_orders > 1 THEN 1 END)
        * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM
(
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) customer_orders;


-- ============================================================
-- 4. TOTAL REVENUE
-- Revenue includes product price and freight value
-- ============================================================

SELECT
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM order_items;


-- ============================================================
-- 5. REVENUE BY PRODUCT CATEGORY
-- ============================================================

SELECT
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;


-- ============================================================
-- 6. MONTHLY REVENUE FOR 2017
-- ============================================================

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE YEAR(o.order_purchase_timestamp) = 2017
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;


-- ============================================================
-- 7. DELIVERED ORDERS AND LATE ORDERS
-- Compare actual delivery date with estimated delivery date
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_rate
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- ============================================================
-- 8. AVERAGE DELAY AMONG LATE ORDERS
-- ============================================================

SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS average_late_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date;


-- ============================================================
-- 9. DELIVERY DELAY BUCKETS
-- ============================================================

SELECT
    CASE
        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 0
            THEN 'On time'
        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 3
            THEN '1-3 days late'
        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 7
            THEN '4-7 days late'
        ELSE '8+ days late'
    END AS delivery_delay_bucket,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_delay_bucket
ORDER BY delivered_orders DESC;


-- ============================================================
-- 10. DELIVERY DELAY AND CUSTOMER REVIEW SCORE
-- ============================================================

SELECT
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) <= 0
            THEN 'On time'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) <= 3
            THEN '1-3 days late'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) <= 7
            THEN '4-7 days late'
        ELSE '8+ days late'
    END AS delivery_delay_bucket,

    COUNT(DISTINCT o.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS average_review_score,

    ROUND(
        SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(r.review_score),
        2
    ) AS low_review_percentage

FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY delivery_delay_bucket

ORDER BY
    CASE delivery_delay_bucket
        WHEN 'On time' THEN 1
        WHEN '1-3 days late' THEN 2
        WHEN '4-7 days late' THEN 3
        WHEN '8+ days late' THEN 4
    END;


-- ============================================================
-- 11. DELIVERY PERFORMANCE BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(DISTINCT o.order_id),
        2
    ) AS late_delivery_rate,

    ROUND(
        AVG(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_estimated_delivery_date
                )
            END
        ),
        2
    ) AS average_late_days

FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY c.customer_state
ORDER BY late_delivery_rate DESC;


-- ============================================================
-- 12. AVERAGE REVIEW SCORE BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_reviews r
    ON o.order_id = r.order_id
GROUP BY c.customer_state
HAVING AVG(r.review_score) < 4
ORDER BY average_review_score;


-- ============================================================
-- 13. TOP SELLERS BY REVENUE
-- ============================================================

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- 14. SELLER DELIVERY PERFORMANCE
-- ============================================================

SELECT
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(DISTINCT o.order_id),
        2
    ) AS late_delivery_rate

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 50

ORDER BY late_delivery_rate DESC;


-- ============================================================
-- 15. PAYMENT METHOD DISTRIBUTION
-- ============================================================

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders
FROM order_payments
GROUP BY payment_type
ORDER BY total_orders DESC;
