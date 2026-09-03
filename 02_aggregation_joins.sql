-- 02_aggregation_joins.sql
-- Part 1, Task 5 — aggregation, join, and HAVING queries against bigbasket_capstone.db

-- ============================================================
-- (a) INNER JOIN orders -> products, GROUP BY category, Delivered only,
--     HAVING total_revenue > 10000
-- ============================================================
SELECT
    p.category,
    COUNT(*) AS order_count,
    SUM(o.amount_inr) AS total_revenue,
    AVG(o.amount_inr) AS avg_revenue
FROM orders AS o
INNER JOIN products AS p ON p.product_id = o.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
HAVING SUM(o.amount_inr) > 10000
ORDER BY total_revenue DESC;

-- ============================================================
-- (b) LEFT JOIN products -> orders, GROUP BY product, counting orders per
--     product with COUNT(o.order_id) — NOT COUNT(*), which would wrongly
--     count the one all-NULL unmatched row as 1 instead of 0.
--     Ordered ascending so the least-ordered products (Premium Face Cream
--     50g with 0 orders) surface first.
-- ============================================================
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(o.order_id) AS total_orders
FROM products AS p
LEFT JOIN orders AS o ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_orders ASC;

-- Sanity check: Premium Face Cream 50g must appear above with total_orders = 0.
-- If it is missing entirely, an INNER JOIN was used by mistake instead of LEFT JOIN.
SELECT
    p.product_id,
    p.product_name,
    COUNT(o.order_id) AS total_orders
FROM products AS p
LEFT JOIN orders AS o ON o.product_id = p.product_id
WHERE p.product_name = 'Premium Face Cream 50g'
GROUP BY p.product_id, p.product_name;
