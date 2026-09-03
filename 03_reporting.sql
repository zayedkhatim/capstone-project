-- 03_reporting.sql
-- Part 1, Task 6 — CASE WHEN tiering, monthly category report, and
-- target-variance derived-fields query against bigbasket_capstone.db

-- ============================================================
-- (a) Tier every product by its total Delivered revenue
--     High   : total_revenue >= 3000
--     Medium : total_revenue >= 1000
--     Low    : total_revenue <  1000
-- ============================================================
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COALESCE(SUM(CASE WHEN o.status = 'Delivered' THEN o.amount_inr END), 0) AS total_revenue,
    CASE
        WHEN COALESCE(SUM(CASE WHEN o.status = 'Delivered' THEN o.amount_inr END), 0) >= 3000 THEN 'High'
        WHEN COALESCE(SUM(CASE WHEN o.status = 'Delivered' THEN o.amount_inr END), 0) >= 1000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_tier
FROM products AS p
LEFT JOIN orders AS o ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- ============================================================
-- (b) Monthly business report by category — Delivered orders only
--     Columns: category, month, order_count, total_revenue, avg_revenue
--     This exact query is exported (unmodified) to monthly_category_revenue.csv
-- ============================================================
SELECT
    p.category AS category,
    strftime('%Y-%m', o.order_date) AS month,
    COUNT(*) AS order_count,
    SUM(o.amount_inr) AS total_revenue,
    AVG(o.amount_inr) AS avg_revenue
FROM orders AS o
INNER JOIN products AS p ON p.product_id = o.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category, strftime('%Y-%m', o.order_date)
ORDER BY p.category, month;

-- ============================================================
-- (c) Target variance — category-level total Delivered revenue vs.
--     category_targets. SQLite integer-division note: total_revenue and
--     target_revenue_inr are both INTEGER, so (total_revenue - target) / target
--     alone truncates to an integer (almost always 0) before *100 ever runs.
--     Multiplying by 100.0 first (as below) forces floating-point division.
-- ============================================================
WITH category_revenue AS (
    SELECT
        p.category,
        SUM(o.amount_inr) AS total_revenue
    FROM orders AS o
    INNER JOIN products AS p ON p.product_id = o.product_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category
)
SELECT
    ct.category,
    ct.target_revenue_inr,
    cr.total_revenue,
    (ct.target_revenue_inr - cr.total_revenue) AS variance,
    ((cr.total_revenue - ct.target_revenue_inr) * 100.0) / ct.target_revenue_inr AS percentage_variance,
    CASE
        WHEN cr.total_revenue >= ct.target_revenue_inr THEN 'Above Target'
        WHEN ((ct.target_revenue_inr - cr.total_revenue) * 100.0) / ct.target_revenue_inr <= 15 THEN 'Below Target - Watch'
        ELSE 'Below Target - Critical'
    END AS target_status
FROM category_targets AS ct
JOIN category_revenue AS cr ON cr.category = ct.category
ORDER BY percentage_variance DESC;
