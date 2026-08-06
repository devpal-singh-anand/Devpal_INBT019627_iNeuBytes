-- ==============================================================================
-- TASK 1: SQL-BASED DESCRIPTIVE ANALYTICS & REPORTING
-- ==============================================================================
-- Author       : Devpal Singh Anand
-- Regd No      : INBT019627
-- Course ID    : DAINB20626
-- Internship   : iNeuBytes VIIP Program — Data Analyst
-- Database     : olist.db (SQLite)
-- ==============================================================================
--
-- HOW TO USE:
-- 1. Open DB Browser for SQLite
-- 2. File → Open Database → select olist.db
-- 3. Go to the "Execute SQL" tab
-- 4. Run each query one at a time (highlight → F5)
-- 5. Inspect the result, screenshot for the report
--
-- DATABASE SUMMARY:
--   Tables: 9  |  Total rows: 1,550,922
--   Orders: 99,441  |  Customers: 99,441  |  Products: 32,951
--   Sellers: 3,095  |  Total Revenue: R$ 13,591,643.70
-- ==============================================================================


-- SECTION 1: DATABASE EXPLORATION

-- 1.1 List all tables in the database
-- Business Question:
-- What tables exist in the Olist database?

-- Technique:
-- Query sqlite_master (SQLite's catalog) to list every table.

SELECT name AS table_name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;
-- Insight:
-- 9 tables are present — orders, customers, order_items, order_payments,
-- order_reviews, products, sellers, geolocation, and a category translation
-- lookup. This gives us enough surface area for joins, aggregations, and
-- cohort analysis without needing any external data.

-- 1.2 Inspect schema of all tables in one shot
-- Business Question:
-- What columns, data types, and primary keys exist in each table?

-- Technique:
-- Use pragma_table_info() for each table, combine them with UNION ALL inside
-- a CTE so we can order by table name + column position. One query, one
-- result set — no need to run 9 separate PRAGMAs.

WITH all_schemas AS (
    SELECT 'customers' AS table_name, cid, name AS column_name, type AS data_type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END AS primary_key,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END AS nullable
    FROM pragma_table_info('customers')
    UNION ALL
    SELECT 'geolocation', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('geolocation')
    UNION ALL
    SELECT 'order_items', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('order_items')
    UNION ALL
    SELECT 'order_payments', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('order_payments')
    UNION ALL
    SELECT 'order_reviews', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('order_reviews')
    UNION ALL
    SELECT 'orders', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('orders')
    UNION ALL
    SELECT 'product_category_name_translation', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('product_category_name_translation')
    UNION ALL
    SELECT 'products', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('products')
    UNION ALL
    SELECT 'sellers', cid, name, type,
           CASE WHEN pk = 1 THEN 'YES' ELSE '' END,
           CASE WHEN "notnull" = 1 THEN 'NOT NULL' ELSE 'NULLABLE' END
    FROM pragma_table_info('sellers')
)
SELECT table_name, column_name, data_type, primary_key, nullable
FROM all_schemas
ORDER BY table_name, cid;
-- Insight:
-- Primary keys are: orders.order_id, customers.customer_id, products.product_id,
-- sellers.seller_id, and product_category_name_translation.product_category_name.
-- order_items, order_payments, and order_reviews use composite keys based on
-- order_id + sequence. Knowing the keys tells us exactly how to join tables.

-- 1.3 Row count for every table
-- Business Question:
-- How big is each table?

-- Technique:
-- COUNT(*) per table, stitched together with UNION ALL.

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
ORDER BY row_count DESC;
-- Insight:
-- geolocation is the heaviest table (1M rows, one row per neighborhood block).
-- sellers is the smallest (3k). orders and customers both have 99,441 rows —
-- one customer_id is generated per order, even for repeat buyers.

-- 1.4 Preview sample rows from each table
-- Business Question:
-- What does a real row look like in each table?

-- Technique:
-- SELECT * ... LIMIT 5. Run these one at a time to inspect each table.

SELECT * FROM orders LIMIT 5;

SELECT * FROM order_items LIMIT 5;

SELECT * FROM order_payments LIMIT 5;

SELECT * FROM order_reviews LIMIT 5;

SELECT * FROM customers LIMIT 5;

SELECT * FROM products LIMIT 5;

SELECT * FROM sellers LIMIT 5;

SELECT * FROM geolocation LIMIT 5;

SELECT * FROM product_category_name_translation LIMIT 5;


-- SECTION 2: DATA QUALITY CHECKS / CLEANING

-- 2.1 Count NULL values in the orders table
-- Business Question:
-- How much missing data exists in the orders table?

-- Technique:
-- Use SUM(CASE WHEN ... IS NULL) to count NULLs per column.

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_delivered_carrier,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered_customer,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM orders
WHERE order_status = 'delivered';
-- Insight:
-- A handful of delivered orders are missing their actual delivery date.
-- This is a data-entry gap. We will exclude these from delivery-time analysis
-- by creating a clean view later.

-- 2.2 Distribution of order_status
-- Business Question:
-- What states do our orders end up in?

-- Technique:
-- GROUP BY status and count, with a percentage of total.

SELECT order_status,
       COUNT(*) AS order_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;
-- Insight:
-- Around 97% of orders are delivered, ~0.6% are canceled, the rest are
-- in-progress states. For analytics, we will mostly work with delivered orders.

-- 2.3 Check for duplicate rows in order_items
-- Business Question:
-- Are there duplicate (order_id, order_item_id) pairs?

-- Technique:
-- Group by the composite key and find groups with more than 1 row.

SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
LIMIT 10;
-- Insight:
-- Returns 0 rows. The composite key (order_id, order_item_id) is unique —
-- no duplicates to clean.

-- 2.4 Detect duplicate zip code prefixes in geolocation
-- Business Question:
-- Is geolocation one row per zip code prefix?

-- Technique:
-- Count rows per zip prefix, show the worst offenders.

SELECT geolocation_zip_code_prefix, COUNT(*) AS row_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
ORDER BY row_count DESC
LIMIT 5;
-- Insight:
-- A single zip prefix maps to hundreds of rows (one per neighborhood block).
-- For joins, we need a deduplicated lookup — created as a view in 2.7.

-- 2.5 Find products with missing category or weight
-- Business Question:
-- How many products have no category or physical attributes?

-- Technique:
-- Count NULLs in key product columns.

SELECT
    COUNT(*) AS total_products,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weight
FROM products;
-- Insight:
-- Around 610 products are missing category, weight, or dimensions.
-- These are retained in the catalog but excluded from category-based
-- aggregations via INNER JOINs.

-- 2.6 Check review comment storage format
-- Business Question:
-- Are empty review comments stored as '' or as NULL?

-- Technique:
-- Count NULLs and empty strings separately.

SELECT
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_message,
    SUM(CASE WHEN review_comment_message = '' THEN 1 ELSE 0 END) AS empty_message
FROM order_reviews;
-- Insight:
-- Most reviews have no written comment (NULL), only a numeric score.
-- No empty strings found, so no conversion needed.

-- 2.7 Create a deduplicated geolocation lookup view
-- Business Question:
-- How do we get one clean lat/lng per zip code prefix?

-- Technique:
-- Aggregate geolocation to one row per zip prefix using AVG(lat) and AVG(lng).

DROP VIEW IF EXISTS v_geolocation_clean;
CREATE VIEW v_geolocation_clean AS
SELECT
    geolocation_zip_code_prefix,
    ROUND(AVG(geolocation_lat), 6) AS lat,
    ROUND(AVG(geolocation_lng), 6) AS lng,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

SELECT * FROM v_geolocation_clean LIMIT 5;
-- Insight:
-- Collapses 1M rows down to ~19K unique zip prefixes. Any query that needs
-- location data can now join against this view instead of the heavy raw table.

-- 2.8 Create a clean orders view for delivered orders
-- Business Question:
-- How do we isolate clean delivered orders for analysis?

-- Technique:
-- Filter to delivered status with non-null key dates.

DROP VIEW IF EXISTS v_orders_clean;
CREATE VIEW v_orders_clean AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL;

SELECT COUNT(*) AS clean_delivered_orders FROM v_orders_clean;
-- Insight:
-- Isolates 96,478 delivered orders with complete date information.
-- This is the dataset we use for delivery-time and trend analysis.

-- 2.9 Check category name casing consistency
-- Business Question:
-- Are category names consistently cased?

-- Technique:
-- List distinct category names and inspect.

SELECT DISTINCT product_category_name
FROM products
WHERE product_category_name IS NOT NULL
ORDER BY product_category_name
LIMIT 10;
-- Insight:
-- Category names are already lowercase and trimmed. No cleaning needed here.

-- 2.10 Check for impossible numeric values
-- Business Question:
-- Are there any negative prices or freight values?

-- Technique:
-- Count rows with price <= 0 or freight < 0, and check the min/max range.

SELECT
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS negative_freight,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM order_items;
-- Insight:
-- No negative values. Price ranges from R$0.85 to R$6,735.
-- Freight ranges from R$0 to R$409. Data is numerically clean.

-- 2.11 Check city name casing and spacing
-- Business Question:
-- Are city names consistently formatted?

-- Technique:
-- Find cities with trailing spaces or inconsistent casing.

SELECT customer_city, COUNT(*) AS occurrences
FROM customers
GROUP BY customer_city
HAVING LENGTH(customer_city) <> LENGTH(TRIM(customer_city))
   OR customer_city <> LOWER(customer_city)
LIMIT 5;
-- Insight:
-- Very few cities have casing/spacing issues. The dataset is clean.
-- For aggregation, LOWER(TRIM(city)) can be used if needed.


-- SECTION 3: BUSINESS ANALYTICS QUERIES

-- Q3.1: Total Revenue Analysis
-- Business Question:
-- What is the total revenue generated by the marketplace?

-- Technique:
-- Basic aggregation (SUM, COUNT) on the order_items table.

SELECT
    ROUND(SUM(price), 2) AS total_revenue_brl,
    ROUND(SUM(freight_value), 2) AS total_freight_brl,
    ROUND(SUM(price) + SUM(freight_value), 2) AS total_gmv_brl,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT order_id) AS total_orders_with_items
FROM order_items;
-- Insight:
-- Total revenue is R$13.59M across 112,650 items sold. Freight adds
-- another R$2.16M, which is ~16% of gross merchandise value.
-- This is the baseline for every other revenue-based query.

-- Q3.2: Average Order Value (AOV)
-- Business Question:
-- What is the average spend per order?

-- Technique:
-- Subquery to sum price per order first, then AVG across orders.

SELECT
    ROUND(AVG(order_total), 2) AS average_order_value_brl,
    ROUND(MIN(order_total), 2) AS min_order_value_brl,
    ROUND(MAX(order_total), 2) AS max_order_value_brl,
    COUNT(*) AS total_orders
FROM (
    SELECT order_id, SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
) AS per_order;
-- Insight:
-- AOV is R$137.75. The max order is R$13,440 — likely a bulk purchase.
-- The gap between min and max is huge, which means a few large orders
-- skew the average. Median would be a useful follow-up metric.

-- Q3.3: Top 10 product categories by revenue
-- Business Question:
-- Which product categories drive the most revenue?

-- Technique:
-- INNER JOIN order_items + products + category translation, then
-- GROUP BY category and ORDER BY revenue DESC.

SELECT
    t.product_category_name_english AS category,
    COUNT(oi.order_id) AS items_sold,
    ROUND(SUM(oi.price), 2) AS revenue_brl,
    ROUND(AVG(oi.price), 2) AS avg_item_price_brl
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY revenue_brl DESC
LIMIT 10;
-- Insight:
-- Health & beauty, watches, and bed/bath/table are the top revenue drivers.
-- The #1 category generates ~R$1.26M — clear category concentration.

-- Q3.4: Revenue by customer state
-- Business Question:
-- Which Brazilian states generate the most revenue?

-- Technique:
-- INNER JOIN orders + customers + order_items, GROUP BY state.

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue_brl,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS revenue_per_order
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue_brl DESC
LIMIT 10;
-- Insight:
-- São Paulo (SP) state alone accounts for 38.28% of total revenue (R$5.20M).
-- That's more than the next 4 states combined. Marketing spend should
-- reflect this geographic concentration.

-- Q3.5: Monthly revenue trend
-- Business Question:
-- How has revenue trended over time?

-- Technique:
-- strftime() to extract year-month from the purchase timestamp,
-- then GROUP BY month and ORDER BY month.

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS revenue_brl
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year_month
ORDER BY year_month;
-- Insight:
-- Revenue grows steadily through 2017, peaks Nov 2017 (Black Friday at
-- ~R$1.01M), then stabilizes around R$900k–1M/month in 2018.
-- The marketplace found its rhythm after the first few months.

-- Q3.6: Payment method distribution
-- Business Question:
-- How do customers prefer to pay?

-- Technique:
-- GROUP BY payment_type with HAVING to filter out tiny categories.

SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value), 2) AS total_paid_brl,
    ROUND(AVG(payment_value), 2) AS avg_payment_brl,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
GROUP BY payment_type
HAVING COUNT(*) > 100
ORDER BY total_paid_brl DESC;
-- Insight:
-- Credit card dominates with R$12.54M (~78.3% of payment value).
-- Boleto (Brazilian payment slip) is #2 at R$2.87M.
-- Voucher and debit card are minor. Payment strategy should focus on
-- credit card experience and installment options.

-- Q3.7: Average review score by product category
-- Business Question:
-- Which product categories have the best and worst reviews?

-- Technique:
-- LEFT JOIN so we keep products with no reviews yet. Filter to categories
-- with at least 50 reviews to avoid noise.

SELECT
    t.product_category_name_english AS category,
    COUNT(r.review_id) AS review_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS low_ratings_count
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
HAVING review_count >= 50
ORDER BY avg_review_score DESC
LIMIT 10;
-- Insight:
-- Top-rated categories (books, tools) average 4.4+ stars.
-- Lowest-rated categories hover around 3.3–3.5 stars.
-- Categories with low ratings need quality or fulfillment review.

-- Q3.8: Top 10 sellers by revenue using RANK()
-- Business Question:
-- Who are our top-performing sellers?

-- Technique:
-- SUM per seller, then RANK() OVER (ORDER BY revenue DESC).

SELECT seller_id, revenue_brl, items_sold, revenue_rank
FROM (
    SELECT
        oi.seller_id,
        ROUND(SUM(oi.price), 2) AS revenue_brl,
        COUNT(*) AS items_sold,
        RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
    FROM order_items oi
    GROUP BY oi.seller_id
) AS ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
-- Insight:
-- The #1 seller has R$229,472 in revenue — clear power-law distribution.
-- Top 3 sellers together generate ~R$653k (~5% of total revenue).
-- Seller concentration is a risk — losing a top seller hurts revenue.

-- Q3.9: Cumulative revenue by month using SUM() OVER
-- Business Question:
-- How fast is the marketplace growing over time?

-- Technique:
-- Window function SUM() OVER (ORDER BY month) for running total.

SELECT year_month,
       monthly_revenue,
       ROUND(SUM(monthly_revenue) OVER (ORDER BY year_month), 2) AS cumulative_revenue
FROM (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year_month
) AS monthly
ORDER BY year_month;
-- Insight:
-- Cumulative revenue crosses R$1M in mid-2017 and reaches R$13.59M by Oct 2018.
-- The growth curve is healthy and non-linear — the marketplace scaled fast
-- after the early months.

-- Q3.10: Month-over-month revenue growth rate using LAG()
-- Business Question:
-- How volatile is monthly revenue?

-- Technique:
-- LAG() to get the previous month's revenue, then compute growth %.

SELECT
    year_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year_month) AS prev_month_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year_month))
        / LAG(monthly_revenue) OVER (ORDER BY year_month),
        2
    ) AS mom_growth_pct
FROM (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year_month
) AS monthly
ORDER BY year_month;
-- Insight:
-- Nov 2017 had the biggest MoM jump (Black Friday effect).
-- Dec 2017 dropped sharply. 2018 months show stable but slightly
-- fluctuating revenue. Volatility is normal for a growing marketplace.

-- Q3.11: Average delivery time
-- Business Question:
-- How long does delivery take on average?

-- Technique:
-- julianday() to compute day differences between purchase and delivery.

SELECT
    ROUND(AVG(julianday(order_delivered_customer_date) -
              julianday(order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(MIN(julianday(order_delivered_customer_date) -
              julianday(order_purchase_timestamp)), 1) AS min_delivery_days,
    ROUND(MAX(julianday(order_delivered_customer_date) -
              julianday(order_purchase_timestamp)), 1) AS max_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
-- Insight:
-- Average delivery takes 12.6 days. The slowest took 209.6 days.
-- The fastest was delivered in 0.5 days. The 209-day outlier is worth
-- investigating — it might be a data entry error or a genuinely lost shipment.

-- Q3.12: On-time vs late delivery rate
-- Business Question:
-- What percentage of orders arrive on time?

-- Technique:
-- Compare actual delivery date vs estimated delivery date using CASE.

SELECT
    COUNT(*) AS total_delivered,
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
             THEN 1 ELSE 0 END) AS on_time_count,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
             THEN 1 ELSE 0 END) AS late_count,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
             THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
             THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
-- Insight:
-- 91.89% of orders arrive on or before the estimated date.
-- 8.11% arrive late. That's 7,826 late deliveries — a logistics
-- improvement opportunity that directly affects customer satisfaction.

-- Q3.13: Find repeat customers using a self-join
-- Business Question:
-- How many customers placed more than one order?

-- Technique:
-- Self-join on the customers table using customer_unique_id.
-- A customer_unique_id with multiple customer_id values is a repeat buyer.

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT c.customer_id) AS total_orders,
    COUNT(DISTINCT o.order_id) AS confirmed_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT c.customer_id) > 1
ORDER BY total_orders DESC
LIMIT 10;
-- Insight:
-- Around 2,997 customers placed 2+ orders (repeat buyers).
-- The most loyal customer placed 17 separate orders.
-- Only 3.12% of customers are repeat buyers — the business is heavily
-- one-time-purchase driven.

-- Q3.14: Review score distribution
-- Business Question:
-- How are review scores distributed?

-- Technique:
-- GROUP BY review_score, count + percentage of total.

SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_reviews), 2) AS pct_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;
-- Insight:
-- 57.78% of reviews are 5 stars, 11.51% are 1 star — bimodal distribution.
-- Customers either love or hate their experience. Few leave neutral 3-star
-- reviews. The 1-star reviews are the actionable bucket.

-- Q3.15: Review score vs delivery time
-- Business Question:
-- Does delivery speed affect customer satisfaction?

-- Technique:
-- CASE bucketing on delivery time, then AVG review score per bucket.

SELECT
    CASE
        WHEN julianday(o.order_delivered_customer_date) -
             julianday(o.order_purchase_timestamp) <= 7 THEN '0-7 days'
        WHEN julianday(o.order_delivered_customer_date) -
             julianday(o.order_purchase_timestamp) <= 14 THEN '8-14 days'
        WHEN julianday(o.order_delivered_customer_date) -
             julianday(o.order_purchase_timestamp) <= 21 THEN '15-21 days'
        ELSE '22+ days'
    END AS delivery_bucket,
    COUNT(r.review_id) AS reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
INNER JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_bucket
ORDER BY MIN(julianday(o.order_delivered_customer_date) -
             julianday(o.order_purchase_timestamp));
-- Insight:
-- Faster delivery → higher reviews. 0-7 day deliveries average 4.42 stars.
-- 22+ day deliveries drop to 3.12 stars. That's a ~1.3 star drop for slow
-- delivery. Speed is the strongest lever for improving satisfaction.

-- Q3.16: Top 5 cities by revenue
-- Business Question:
-- Which cities generate the most revenue?

-- Technique:
-- Multi-table INNER JOIN (orders + customers + order_items).

SELECT
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS revenue_brl
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_city
ORDER BY revenue_brl DESC
LIMIT 5;
-- Insight:
-- São Paulo city alone generates R$1.91M (~14.1% of total revenue).
-- Rio de Janeiro is #2 at R$992k. Belo Horizonte is #3 at R$355k.
-- Urban concentration is extreme — last-mile logistics should focus here.

-- Q3.17: Products never sold (anti-join)
-- Business Question:
-- Is there dead inventory in the catalog?

-- Technique:
-- LEFT JOIN where the right side is NULL (anti-join pattern).

SELECT
    COUNT(DISTINCT p.product_id) AS never_sold_product_count,
    ROUND(100.0 * COUNT(DISTINCT p.product_id) /
          (SELECT COUNT(*) FROM products), 2) AS pct_of_catalog
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_id IS NULL;
-- Insight:
-- All 32,951 products in the catalog have been sold at least once.
-- No dead inventory — Olist's catalog is curated for active sellers.

-- Q3.18: Revenue concentration by quartile using NTILE()
-- Business Question:
-- Does the Pareto principle apply to product revenue?

-- Technique:
-- NTILE(4) to split products into 4 revenue quartiles.

SELECT revenue_quartile,
       COUNT(*) AS products_in_quartile,
       ROUND(SUM(revenue_brl), 2) AS total_revenue_brl,
       ROUND(AVG(revenue_brl), 2) AS avg_revenue_per_product
FROM (
    SELECT
        p.product_id,
        SUM(oi.price) AS revenue_brl,
        NTILE(4) OVER (ORDER BY SUM(oi.price) DESC) AS revenue_quartile
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id
) AS quartiled
GROUP BY revenue_quartile
ORDER BY revenue_quartile;
-- Insight:
-- Top 25% of products generate 79.3% of revenue (Pareto principle holds).
-- Top 50% of products generate 92.1% of revenue.
-- The bottom 50% of products barely contribute — a candidate for cleanup.

-- Q3.19: Most common payment installments
-- Business Question:
-- How do customers use installment plans?

-- Technique:
-- GROUP BY installments, percentage of total credit card transactions.

SELECT
    payment_installments AS installments,
    COUNT(*) AS transaction_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_payments
                              WHERE payment_type = 'credit_card'), 2) AS pct_of_transactions,
    ROUND(AVG(payment_value), 2) AS avg_payment_brl
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY transaction_count DESC
LIMIT 10;
-- Insight:
-- 33.15% of credit card payments are paid in full (1 installment).
-- 2-installment plans are #2 at 16.16%. Installment culture is strong in Brazil —
-- the marketplace should support flexible installment options.

-- Q3.20: Freight ratio by product weight bucket
-- Business Question:
-- How does freight cost scale with product weight?

-- Technique:
-- CASE bucketing on weight, then AVG(freight/price) ratio.

SELECT
    CASE
        WHEN product_weight_g < 500 THEN '0-500g'
        WHEN product_weight_g < 2000 THEN '500g-2kg'
        WHEN product_weight_g < 5000 THEN '2-5kg'
        WHEN product_weight_g < 10000 THEN '5-10kg'
        ELSE '10kg+'
    END AS weight_bucket,
    COUNT(*) AS items,
    ROUND(AVG(price), 2) AS avg_price_brl,
    ROUND(AVG(freight_value), 2) AS avg_freight_brl,
    ROUND(100.0 * AVG(freight_value) / AVG(price), 2) AS freight_to_price_pct
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
WHERE p.product_weight_g IS NOT NULL
GROUP BY weight_bucket
ORDER BY MIN(p.product_weight_g);
-- Insight:
-- Lighter items (0-500g) have the HIGHEST freight-to-price ratio (20.17%)
-- because minimum freight costs dominate cheap items.
-- Heavier items (5-10kg) drop to 16.67% — freight scales sub-linearly
-- with weight. Light items are margin-dilutive on freight.


-- SECTION 4: KPIs & COHORT ANALYSIS

-- Q4.1: Six core business KPIs in a single query
-- Business Question:
-- What are the 6 core KPIs for the Olist marketplace?

-- Technique:
-- Subqueries for each KPI, combined into a single SELECT.

SELECT
    (SELECT ROUND(SUM(price), 2) FROM order_items) AS kpi_total_revenue_brl,

    (SELECT ROUND(AVG(order_total), 2)
     FROM (SELECT order_id, SUM(price) AS order_total FROM order_items GROUP BY order_id)
    ) AS kpi_average_order_value_brl,

    (SELECT COUNT(*) FROM orders) AS kpi_total_orders,

    (SELECT COUNT(DISTINCT customer_unique_id) FROM customers) AS kpi_unique_customers,

    (SELECT ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2)
     FROM (
         SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
         FROM customers c
         LEFT JOIN orders o ON c.customer_id = o.customer_id
         GROUP BY c.customer_unique_id
     )
    ) AS kpi_repeat_purchase_rate_pct,

    (SELECT ROUND(AVG(review_score), 2) FROM order_reviews) AS kpi_avg_review_score;
-- Insight:
-- AOV = R$137.75. Repeat Purchase Rate = 3.12%. Avg Review = 4.09 stars.
-- The repeat purchase rate is critically low — the business depends on
-- new customer acquisition more than retention.

-- Q4.2: Monthly KPI trend table
-- Business Question:
-- How do all 6 KPIs trend month-over-month?

-- Technique:
-- CTEs for monthly orders, items, and reviews, joined on year_month.

WITH monthly_orders AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
        o.order_id,
        c.customer_unique_id
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
),
monthly_items AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
        SUM(oi.price) AS revenue,
        COUNT(*) AS items
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY 1
),
monthly_reviews AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
        AVG(r.review_score) AS avg_score,
        COUNT(r.review_id) AS review_count
    FROM orders o
    INNER JOIN order_reviews r ON o.order_id = r.order_id
    GROUP BY 1
)
SELECT
    m.year_month,
    COUNT(DISTINCT m.order_id) AS orders,
    COUNT(DISTINCT m.customer_unique_id) AS unique_customers,
    ROUND(mi.revenue, 2) AS revenue_brl,
    ROUND(mi.revenue / COUNT(DISTINCT m.order_id), 2) AS aov_brl,
    ROUND(mr.avg_score, 2) AS avg_review_score
FROM monthly_orders m
LEFT JOIN monthly_items mi ON m.year_month = mi.year_month
LEFT JOIN monthly_reviews mr ON m.year_month = mr.year_month
GROUP BY m.year_month
ORDER BY m.year_month;
-- Insight:
-- Monthly KPIs show steady growth through 2017, with AOV fluctuating
-- between R$130-180. Review scores remain stable around 4.0-4.2 throughout.
-- The marketplace found a stable operating rhythm after mid-2017.

-- Q4.3: Cohort Analysis — Customer Retention by Acquisition Month
-- Business Question:
-- What percentage of customers acquired in month X come back in month X+1,
-- X+2, and so on?

-- Technique:
-- Step 1: Find each customer's first purchase month (their cohort).
-- Step 2: Find every month each customer made a purchase (activity month).
-- Step 3: Calculate month_index = activity_month - cohort_month (in months).
-- Step 4: For each cohort + month_index, COUNT DISTINCT customers who were
--         active (NOT count months). This is the fix — earlier version was
--         counting activity_month values instead of actual customers.
-- Step 5: Divide active_customers by cohort_size to get retention %.

WITH customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        strftime('%Y-%m', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT
        c.customer_unique_id,
        strftime('%Y-%m', o.order_purchase_timestamp) AS activity_month
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY c.customer_unique_id, activity_month
),
cohort_data AS (
    SELECT
        f.cohort_month,
        a.customer_unique_id,
        ((CAST(SUBSTR(a.activity_month, 1, 4) AS INTEGER) * 12
          + CAST(SUBSTR(a.activity_month, 6, 2) AS INTEGER))
         -
         (CAST(SUBSTR(f.cohort_month, 1, 4) AS INTEGER) * 12
          + CAST(SUBSTR(f.cohort_month, 6, 2) AS INTEGER))) AS month_index
    FROM customer_first_purchase f
    INNER JOIN customer_activity a ON f.customer_unique_id = a.customer_unique_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    cs.cohort_size AS customers_acquired,
    cd.month_index,
    COUNT(DISTINCT cd.customer_unique_id) AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT cd.customer_unique_id) / cs.cohort_size, 2) AS retention_pct
FROM cohort_data cd
INNER JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_index <= 6
GROUP BY cd.cohort_month, cd.month_index, cs.cohort_size
ORDER BY cd.cohort_month, cd.month_index;
-- Insight:
-- Month 0 retention is 100% by definition (the customer just signed up).
-- Month 1 retention drops to ~0.4% — only 3-9 customers out of every 1,000
-- return in the month after their first purchase.
-- Month 6 retention is also ~0.4%. The business is a one-time-purchase
-- marketplace. Growth depends on new customer acquisition, not retention.

-- Q4.4: Cohort retention pivot table (M0 to M6)
-- Business Question:
-- Can we see retention as a clean pivot table?

-- Technique:
-- Same CTE structure as Q4.3, but pivot the month_index into columns
-- using conditional aggregation (CASE WHEN inside COUNT DISTINCT).
-- This produces the classic cohort triangle view.

WITH customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        strftime('%Y-%m', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT
        c.customer_unique_id,
        strftime('%Y-%m', o.order_purchase_timestamp) AS activity_month
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY c.customer_unique_id, activity_month
),
cohort_indexed AS (
    SELECT
        f.cohort_month,
        a.customer_unique_id,
        ((CAST(SUBSTR(a.activity_month,1,4) AS INTEGER)*12
          + CAST(SUBSTR(a.activity_month,6,2) AS INTEGER))
         -
         (CAST(SUBSTR(f.cohort_month,1,4) AS INTEGER)*12
          + CAST(SUBSTR(f.cohort_month,6,2) AS INTEGER))) AS month_index
    FROM customer_first_purchase f
    INNER JOIN customer_activity a ON f.customer_unique_id = a.customer_unique_id
)
SELECT
    cohort_month AS "Cohort Month",
    COUNT(DISTINCT CASE WHEN month_index = 0 THEN customer_unique_id END) AS "M0",
    COUNT(DISTINCT CASE WHEN month_index = 1 THEN customer_unique_id END) AS "M1",
    COUNT(DISTINCT CASE WHEN month_index = 2 THEN customer_unique_id END) AS "M2",
    COUNT(DISTINCT CASE WHEN month_index = 3 THEN customer_unique_id END) AS "M3",
    COUNT(DISTINCT CASE WHEN month_index = 4 THEN customer_unique_id END) AS "M4",
    COUNT(DISTINCT CASE WHEN month_index = 5 THEN customer_unique_id END) AS "M5",
    COUNT(DISTINCT CASE WHEN month_index = 6 THEN customer_unique_id END) AS "M6"
FROM cohort_indexed
GROUP BY cohort_month
HAVING COUNT(DISTINCT CASE WHEN month_index = 0 THEN customer_unique_id END) >= 100
ORDER BY cohort_month
LIMIT 12;
-- Insight:
-- M0 is always equal to the cohort size (100% retention by definition).
-- M1 through M6 are tiny — single digits per cohort of hundreds.
-- The diagonal pattern (each cohort declining over time) is the classic
-- shape of a one-time-purchase marketplace.


-- SECTION 5: REPORTING SUMMARY

-- Q5.1: Summary of all 20 business questions answered
-- Business Question:
-- What did we learn from the analysis?

-- Technique:
-- Documentation only. No query. This is the written summary for the report.

-- Q3.1  — Total revenue is R$13.59M across 112,650 items sold.
-- Q3.2  — AOV is R$137.75. Max order is R$13,440.
-- Q3.3  — Health & beauty is the top revenue category at ~R$1.26M.
-- Q3.4  — São Paulo (SP) state = 38.28% of total revenue.
-- Q3.5  — Revenue peaks Nov 2017 (Black Friday at ~R$1.01M).
-- Q3.6  — Credit card = 78.3% of payment value; boleto = 17.9%.
-- Q3.7  — Top-rated categories average 4.4+ stars; lowest hover at 3.3-3.5.
-- Q3.8  — #1 seller has R$229,472 in revenue (power-law distribution).
-- Q3.9  — Cumulative revenue crosses R$1M in mid-2017.
-- Q3.10 — Nov 2017 had the biggest MoM jump (Black Friday).
-- Q3.11 — Average delivery takes 12.6 days.
-- Q3.12 — 91.89% of orders arrive on time.
-- Q3.13 — Only 3.12% of customers are repeat buyers.
-- Q3.14 — 57.78% of reviews are 5 stars; 11.51% are 1 star (bimodal).
-- Q3.15 — Faster delivery → higher reviews (4.42★ vs 3.12★).
-- Q3.16 — São Paulo city generates R$1.91M (~14.1% of total revenue).
-- Q3.17 — All 32,951 products have been sold (no dead inventory).
-- Q3.18 — Top 25% of products generate 79.3% of revenue (Pareto).
-- Q3.19 — 33.15% of credit card payments are 1-installment (paid in full).
-- Q3.20 — Light items (0-500g) have the highest freight-to-price ratio (20.17%).

-- KPIs (VERIFIED):
--   Total Revenue:        R$ 13,591,643.70
--   Average Order Value:  R$ 137.75
--   Total Orders:         99,441
--   Unique Customers:     96,096
--   Repeat Purchase Rate: 3.12%
--   Avg Review Score:     4.09 / 5.0
--   On-time Delivery:     91.89%
--   Avg Delivery Time:    12.6 days

-- COHORT INSIGHT:
--   Customer retention drops from 100% (month 0) to ~0.4% (month 1).
--   The business is heavily one-time-purchase driven. Growth depends on
--   new customer acquisition more than retention.

-- ==============================================================================
-- END OF TASK 1 SQL SCRIPT
-- ==============================================================================
