-- 01_foundations.sql
-- Part 1, Task 4 — foundational SQL queries against bigbasket_capstone.db
-- Each concept is its own labelled, runnable query.

-- ============================================================
-- 1. SELECT / WHERE — orders placed by customers in a specific city
--    (city lives on customers, so we join orders to customers on customer_id)
-- ============================================================
SELECT o.order_id, o.order_date, c.name AS customer_name, c.city, o.amount_inr, o.status
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE c.city = 'Bengaluru';

-- ============================================================
-- 2. DISTINCT — every distinct product category
-- ============================================================
SELECT DISTINCT category
FROM products
ORDER BY category;

-- ============================================================
-- 3. ORDER BY + LIMIT — the 5 highest-value orders by amount_inr
-- ============================================================
SELECT order_id, customer_id, product_id, order_date, amount_inr, status
FROM orders
ORDER BY amount_inr DESC
LIMIT 5;

-- ============================================================
-- 4. Alias (AS) — rename an aggregate in the output
-- ============================================================
SELECT status, COUNT(*) AS total_orders
FROM orders
GROUP BY status
ORDER BY status;

-- ============================================================
-- 5. IN — orders whose payment_mode is in a 2-mode list
-- ============================================================
SELECT order_id, order_date, payment_mode, amount_inr, status
FROM orders
WHERE payment_mode IN ('UPI', 'Credit Card');

-- ============================================================
-- 6. BETWEEN — orders with amount_inr within a stated range (₹200–₹500 inclusive)
-- ============================================================
SELECT order_id, order_date, amount_inr, status
FROM orders
WHERE amount_inr BETWEEN 200 AND 500
ORDER BY amount_inr;

-- ============================================================
-- 6b. NOT BETWEEN — orders with amount_inr outside that same ₹200–₹500 range
-- ============================================================
SELECT order_id, order_date, amount_inr, status
FROM orders
WHERE amount_inr NOT BETWEEN 200 AND 500
ORDER BY amount_inr;

-- ============================================================
-- 7. IS NULL — orders with no rating recorded
--    (only Delivered orders ever receive a rating; every Cancelled/Pending
--     order has rating IS NULL by construction in generate_data.py)
-- ============================================================
SELECT order_id, order_date, status, rating
FROM orders
WHERE rating IS NULL
ORDER BY order_id;

-- Sanity check referenced in the brief: confirms the IS NULL rows above are
-- exactly the Cancelled + Pending orders (42 + 24 = 66 rows), and that no
-- Delivered order is ever missing a rating.
SELECT
    (SELECT COUNT(*) FROM orders WHERE rating IS NULL) AS null_rating_count,
    (SELECT COUNT(*) FROM orders WHERE status IN ('Cancelled', 'Pending')) AS cancelled_plus_pending,
    (SELECT COUNT(*) FROM orders WHERE status = 'Delivered' AND rating IS NULL) AS delivered_missing_rating;
