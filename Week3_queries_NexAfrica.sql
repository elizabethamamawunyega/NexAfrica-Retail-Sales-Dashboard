=====================================================================
   WEEK 3 - PRODUCT & CUSTOMER ANALYSIS
===================================================================== 

/* ----------------- PART A: PRODUCT ANALYSIS ----------------- */

-- Top 10 products by sales
SELECT product_name, SUM(sales) AS total_sales
FROM superstore
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- Top 10 products by profit
SELECT product_name, SUM(profit) AS total_profit
FROM superstore
GROUP BY product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Bottom 10 products by profit (the loss-makers)
SELECT product_name, SUM(profit) AS total_profit
FROM superstore
GROUP BY product_name
ORDER BY total_profit ASC
LIMIT 10;

-- Sub-Category analysis: sales, profit, quantity
SELECT
    sub_category,
    SUM(sales)      AS total_sales,
    SUM(profit)     AS total_profit,
    SUM(quantity)   AS total_quantity,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct
FROM superstore
GROUP BY sub_category
ORDER BY total_profit ASC;

-- Category-level summary (for "which category performs best")
SELECT
    category,
    SUM(sales)      AS total_sales,
    SUM(profit)     AS total_profit,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;

-- Products with negative profit (answers "which products have negative profit")
SELECT product_name, SUM(profit) AS total_profit
FROM superstore
GROUP BY product_name
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;


----------------- PART B: CUSTOMER ANALYSIS ----------------- 

-- Total customers 
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM superstore;

--Per-customer summary: sales, orders, profit, avg order value
SELECT
    customer_id,
    customer_name,
    SUM(sales)                                AS total_sales,
    COUNT(DISTINCT order_id)                  AS total_orders,
    SUM(profit)                               AS total_profit,
    SUM(sales) / COUNT(DISTINCT order_id)     AS avg_order_value
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY total_sales DESC;

-- Customer segmentation (High / Medium / Low value)
-- Thresholds: High = top 20% by sales, Medium = next 30%, Low = bottom 50%
-- Uses a CTE to calculate percentile cutoffs, then labels each customer.

WITH customer_sales AS (
    SELECT
        customer_id,
        customer_name,
        SUM(sales)  AS total_sales,
        SUM(profit) AS total_profit
    FROM superstore
    GROUP BY customer_id, customer_name
),
ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY total_sales) AS pct_rank
    FROM customer_sales
)
SELECT
    customer_id,
    customer_name,
    total_sales,
    total_profit,
    CASE
        WHEN pct_rank >= 0.80 THEN 'High-Value'
        WHEN pct_rank >= 0.50 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS customer_segment
FROM ranked
ORDER BY total_sales DESC;

--Segment summary: how many customers and how much revenue per tier
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(sales)  AS total_sales,
        SUM(profit) AS total_profit
    FROM superstore
    GROUP BY customer_id
),
ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY total_sales) AS pct_rank
    FROM customer_sales
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN pct_rank >= 0.80 THEN 'High-Value'
            WHEN pct_rank >= 0.50 THEN 'Medium-Value'
            ELSE 'Low-Value'
        END AS customer_segment
    FROM ranked
)
SELECT
    customer_segment,
    COUNT(*)              AS num_customers,
    SUM(total_sales)      AS segment_sales,
    SUM(total_profit)     AS segment_profit
FROM segmented
GROUP BY customer_segment
ORDER BY segment_sales DESC;

