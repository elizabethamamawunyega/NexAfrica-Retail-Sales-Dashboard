 SELECT
    COUNT(DISTINCT order_id)     AS total_orders,
    COUNT(DISTINCT customer_id)  AS total_customers,
    COUNT(DISTINCT product_id)   AS total_products,
    COUNT(DISTINCT category)     AS total_categories,
    COUNT(DISTINCT region)       AS total_regions
FROM superstore4;      -- Distinct counts for key entities  

 SELECT 'Sales' AS variable, MIN(sales) AS min_value, MAX(sales) AS max_value, AVG(sales) AS avg_value
FROM superstore4
UNION ALL
SELECT 'Profit', MIN(profit), MAX(profit), AVG(profit)
FROM superstore4
UNION ALL
SELECT 'Quantity', MIN(quantity), MAX(quantity), AVG(quantity)
FROM superstore4
UNION ALL
SELECT 'Discount', MIN(discount), MAX(discount), AVG(discount)
FROM superstore4; -- Min, Max, Avg for numeric fields  

 -- Category
SELECT category, COUNT(*) AS row_count
FROM superstore4
GROUP BY category
ORDER BY row_count DESC; 

-- Region
SELECT region, COUNT(*) AS row_count
FROM superstore4
GROUP BY region
ORDER BY row_count DESC; 

-- Segment 
SELECT segment, COUNT(*) AS row_count
FROM superstore4
GROUP BY segment
ORDER BY row_count DESC;

-- Ship Mode
SELECT ship_mode, COUNT(*) AS row_count
FROM superstore4
GROUP BY ship_mode
ORDER BY row_count DESC;
-- Categorical Distributions 

  SELECT 
    -- 1. Total Sales
    SUM(sales) AS total_sales,
    
    -- 2. Total Profit
    SUM(profit) AS total_profit,
    
    -- 3. Total Orders (Distinct Order IDs)
    COUNT(DISTINCT order_id) AS total_orders,
    
    -- 4. Total Customers (Distinct Customer IDs)
    COUNT(DISTINCT customer_id) AS total_customers,
    
    -- 5. Total Quantity
    SUM(quantity) AS total_quantity,
    
    -- 6. Profit Margin (Total Profit / Total Sales)
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct,
    
    -- 7. Average Order Value (Total Sales / Total Orders)
    SUM(sales) / COUNT(DISTINCT order_id) AS average_order_value
FROM superstore4; --  KPIs  

 WITH yearly_sales AS (
    SELECT 
        YEAR(order_date) AS order_year,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        COUNT(DISTINCT order_id) AS total_orders
    FROM superstore4
    GROUP BY YEAR(order_date)
)
SELECT 
    order_year,
    total_sales,
    total_profit,
    total_orders,
    LAG(total_sales) OVER (ORDER BY order_year) AS prev_year_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY order_year)) / LAG(total_sales) OVER (ORDER BY order_year)) * 100 AS yoy_sales_growth_pct
FROM yearly_sales
ORDER BY order_year; -- Sales&profit by year  

 SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS _year_month,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM superstore4
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY _year_month; -- sales trend by year-month  

 SELECT 
    MONTH(order_date) AS month_num,
    MONTHNAME(order_date) AS month_name,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM superstore4 
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_num; -- sales by calendar month  

 SELECT 
    region,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY region
ORDER BY total_profit DESC; 

SELECT 
    category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY category
ORDER BY total_profit DESC; 

 SELECT 
    category,
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY category, sub_category
ORDER BY total_profit ASC;   

SELECT 
    segment,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY segment
ORDER BY total_profit DESC; -- Performance metrics  

  SELECT 
    CASE 
        WHEN discount = 0 THEN '0% (No Discount)'
        WHEN discount > 0 AND discount <= 0.15 THEN '1% - 15%'
        WHEN discount > 0.15 AND discount <= 0.25 THEN '16% - 25%'
        WHEN discount > 0.25 AND discount <= 0.35 THEN '36% - 35%'
        ELSE 'Over 35%'
    END AS discount_band,
    
    COUNT(*) AS total_order_lines,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(quantity) AS avg_quantity_per_line,
    (SUM(profit) / SUM(sales)) * 100 AS profit_margin_pct
FROM superstore4
GROUP BY 
    CASE 
        WHEN discount = 0 THEN '0% (No Discount)'
        WHEN discount > 0 AND discount <= 0.15 THEN '1% - 15%'
        WHEN discount > 0.15 AND discount <= 0.25 THEN '16% - 25%'
        WHEN discount > 0.25 AND discount <= 0.35 THEN '36% - 35%'
        ELSE 'Over 35%'
    END
ORDER BY MIN(discount); -- correlation&discount analysis  

 SELECT 
    product_id,
    product_name,
    category,
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM superstore4
GROUP BY product_id, product_name, category, sub_category
ORDER BY total_sales DESC
LIMIT 10;

SELECT 
    product_id,
    product_name,
    category,
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM superstore4
GROUP BY product_id, product_name, category, sub_category
ORDER BY total_profit ASC
LIMIT 10;

SELECT 
    product_id,
    product_name,
    category,
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY product_id, product_name, category, sub_category
HAVING SUM(sales) >= 5000 AND SUM(profit) < 0
ORDER BY total_profit ASC;  

 SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM superstore4
GROUP BY customer_id, customer_name, segment
ORDER BY total_sales DESC
LIMIT 10; 

WITH customer_totals AS (
    SELECT 
        customer_id,
        customer_name,
        SUM(sales) AS lifetime_sales,
        SUM(profit) AS lifetime_profit
    FROM superstore4
    GROUP BY customer_id, customer_name
)
SELECT 
    COUNT(*) AS total_unprofitable_customers,
    SUM(lifetime_profit) AS combined_net_loss,
    AVG(lifetime_profit) AS avg_customer_loss
FROM customer_totals
WHERE lifetime_profit < 0; 

SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(discount) * 100 AS avg_discount_pct
FROM superstore4
GROUP BY customer_id, customer_name, segment
HAVING SUM(profit) < 0
ORDER BY total_profit ASC; 
