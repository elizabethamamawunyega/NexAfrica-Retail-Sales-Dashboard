/* -- build the full cohort table in one query using chained CTEs.
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_purchase_date
    FROM superstore4
    GROUP BY customer_id
),

orders_with_cohort AS (
    SELECT
        s.customer_id,
        s.order_date,
        f.first_purchase_date,
        DATE_FORMAT(f.first_purchase_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(s.order_date, '%Y-%m')          AS order_month,
        (YEAR(s.order_date) - YEAR(f.first_purchase_date)) * 12
            + (MONTH(s.order_date) - MONTH(f.first_purchase_date)) AS cohort_index
    FROM superstore4 s
    JOIN first_purchase f ON s.customer_id = f.customer_id
)

-- count distinct customers per cohort per cohort_index
SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders_with_cohort
GROUP BY cohort_month, cohort_index
ORDER BY cohort_month, cohort_index;


-- cohort sizes (how many NEW customers joined each month)
   
   WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_purchase_date
    FROM superstore4
    GROUP BY customer_id
)
SELECT
    DATE_FORMAT(first_purchase_date, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT customer_id) AS new_customers
FROM first_purchase
GROUP BY DATE_FORMAT(first_purchase_date, '%Y-%m')
ORDER BY cohort_month;


-- Step 6b: revenue per cohort (which cohort generated the most revenue)
   WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_purchase_date
    FROM superstore4
    GROUP BY customer_id
)
SELECT
    DATE_FORMAT(f.first_purchase_date, '%Y-%m') AS cohort_month,
    SUM(s.sales)                                AS total_revenue,
    COUNT(DISTINCT s.customer_id)               AS customers_in_cohort
FROM superstore4 s
JOIN first_purchase f ON s.customer_id = f.customer_id
GROUP BY DATE_FORMAT(f.first_purchase_date, '%Y-%m')
ORDER BY total_revenue DESC;


-- average retention rate by cohort_index, across ALL cohorts
-- "how does activity change after the first purchase"
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_purchase_date
    FROM superstore4
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT
        s.customer_id,
        DATE_FORMAT(f.first_purchase_date, '%Y-%m') AS cohort_month,
        (YEAR(s.order_date) - YEAR(f.first_purchase_date)) * 12
            + (MONTH(s.order_date) - MONTH(f.first_purchase_date)) AS cohort_index
    FROM superstore4 s
    JOIN first_purchase f ON s.customer_id = f.customer_id
),
cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM orders_with_cohort
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    c.cohort_index,
    AVG(c.active_customers / s.cohort_size) * 100 AS avg_retention_pct
FROM cohort_counts c
JOIN cohort_sizes s ON c.cohort_month = s.cohort_month
WHERE c.cohort_index BETWEEN 0 AND 6
GROUP BY c.cohort_index
ORDER BY c.cohort_index; */ 

-- DISCOUNT ANALYSIS
-- Which products receive the highest average discount
SELECT
    product_name,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY product_name
ORDER BY avg_discount_pct DESC
LIMIT 10;


-- Does higher discount increase sales volume?
-- Compare average quantity sold across discount bands.
SELECT
    CASE
        WHEN discount = 0       THEN '0%'
        WHEN discount <= 0.15   THEN '1-15%'
        WHEN discount <= 0.25   THEN '16-25%'
        WHEN discount <= 0.35   THEN '26-35%'
        ELSE                          'Over 35%'
    END AS discount_band,
    COUNT(*)            AS line_items,
    SUM(sales)           AS total_sales,
    AVG(quantity)         AS avg_quantity_per_line
FROM superstore4
GROUP BY
    CASE
        WHEN discount = 0       THEN '0%'
        WHEN discount <= 0.15   THEN '1-15%'
        WHEN discount <= 0.25   THEN '16-25%'
        WHEN discount <= 0.35   THEN '26-35%'
        ELSE                          'Over 35%'
    END
ORDER BY discount_band;


-- Does higher discount reduce profit?
-- Same bands, now looking at profit and margin instead of quantity.
SELECT
    CASE
        WHEN discount = 0       THEN '0%'
        WHEN discount <= 0.15   THEN '1-15%'
        WHEN discount <= 0.25   THEN '16-25%'
        WHEN discount <= 0.35   THEN '26-35%'
        ELSE                          'Over 35%'
    END AS discount_band,
    SUM(sales)                          AS total_sales,
    SUM(profit)                         AS total_profit,
    (SUM(profit) / SUM(sales)) * 100    AS profit_margin_pct
FROM superstore4
GROUP BY
    CASE
        WHEN discount = 0       THEN '0%'
        WHEN discount <= 0.15   THEN '1-15%'
        WHEN discount <= 0.25   THEN '16-25%'
        WHEN discount <= 0.35   THEN '26-35%'
        ELSE                          'Over 35%'
    END
ORDER BY discount_band;


-- Which categories are most affected by discounting?
SELECT
    category,
    AVG(discount) * 100                 AS avg_discount_pct,
    SUM(sales)                          AS total_sales,
    SUM(profit)                         AS total_profit,
    (SUM(profit) / SUM(sales)) * 100    AS profit_margin_pct
FROM superstore4
GROUP BY category
ORDER BY avg_discount_pct DESC;


-- PROFITABILITY ANALYSIS
-- Classify each sub-category into one of 4 profitability quadrants,
-- splitting "high" vs "low" at the median sales and median profit
WITH subcat_totals AS (
    SELECT
        sub_category,
        SUM(sales)  AS total_sales,
        SUM(profit) AS total_profit
    FROM superstore4
    GROUP BY sub_category
),
medians AS (
    SELECT
        -- here we just use AVG() as a practical stand-in threshold.
        AVG(total_sales)  AS median_sales,
        AVG(total_profit) AS median_profit
    FROM subcat_totals
)
SELECT
    s.sub_category,
    s.total_sales,
    s.total_profit,
    CASE
        WHEN s.total_sales >= m.median_sales AND s.total_profit >= m.median_profit
            THEN 'High-Sales / High-Profit'
        WHEN s.total_sales >= m.median_sales AND s.total_profit < m.median_profit
            THEN 'High-Sales / Low-Profit'
        WHEN s.total_sales < m.median_sales AND s.total_profit >= m.median_profit
            THEN 'Low-Sales / High-Profit'
        ELSE 'Low-Sales / Low-Profit'
    END AS profitability_quadrant
FROM subcat_totals s
CROSS JOIN medians m
ORDER BY profitability_quadrant, s.total_profit DESC;

WITH product_totals AS (
    SELECT
        product_name,
        SUM(sales)  AS total_sales,
        SUM(profit) AS total_profit
    FROM superstore4
    GROUP BY product_name
    HAVING SUM(sales) > 1000   -- ignore very small/rare products
),
medians AS (
    SELECT
        AVG(total_sales)  AS median_sales,
        AVG(total_profit) AS median_profit
    FROM product_totals
)
SELECT
    p.product_name,
    p.total_sales,
    p.total_profit,
    CASE
        WHEN p.total_sales >= m.median_sales AND p.total_profit >= m.median_profit
            THEN 'High-Sales / High-Profit'
        WHEN p.total_sales >= m.median_sales AND p.total_profit < m.median_profit
            THEN 'High-Sales / Low-Profit'
        WHEN p.total_sales < m.median_sales AND p.total_profit >= m.median_profit
            THEN 'Low-Sales / High-Profit'
        ELSE 'Low-Sales / Low-Profit'
    END AS profitability_quadrant
FROM product_totals p
CROSS JOIN medians m
ORDER BY profitability_quadrant, p.total_profit DESC;

