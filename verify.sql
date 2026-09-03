-- verify.sql
-- Verification queries run against bigbasket_capstone.db immediately after
-- generate_data.py (unmodified, random.seed(42)) was executed.
--
-- Expected / actual results (captured in verify_output.txt):
--   products         : 31
--   customers        : 50
--   orders           : 500
--   category_targets : 6
--   orders.status split -> Delivered 434, Cancelled 42, Pending 24
--   Zero-order product  -> product_id 31, "Premium Face Cream 50g"

SELECT COUNT(*) AS product_count FROM products;

SELECT COUNT(*) AS customer_count FROM customers;

SELECT COUNT(*) AS order_count FROM orders;

SELECT COUNT(*) AS target_count FROM category_targets;

SELECT status, COUNT(*) AS n
FROM orders
GROUP BY status
ORDER BY status;

-- Sanity check: confirms Premium Face Cream 50g is the one product with no orders
SELECT product_id, product_name
FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM orders);
