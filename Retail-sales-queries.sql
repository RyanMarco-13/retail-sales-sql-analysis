-- ============================================
-- SECTION 1: DATABASE SETUP
-- ============================================
create database retail_sales_data;
use retail_sales_data;

-- ============================================
-- SECTION 2: STAGING TABLE (import raw CSV without type errors)
-- ============================================
create table staging_data(
transaction_id VARCHAR(20), 
customer_id VARCHAR(20), 
category VARCHAR(50), 
item VARCHAR(50), 
price_per_unit VARCHAR(20), 
quantity VARCHAR(20), 
total_spent VARCHAR(20), 
payment_method VARCHAR(30), 
location VARCHAR(20), 
transaction_date VARCHAR(20), 
discount_applied VARCHAR(20));

-- Final table with proper data types
CREATE TABLE retail_sales (
    transaction_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    category VARCHAR(50),
    item VARCHAR(50),
    price_per_unit DECIMAL(10,2),
    quantity INT,
    total_spent DECIMAL(10,2),
    payment_method VARCHAR(30),
    location VARCHAR(20),
    transaction_date DATE,
    discount_applied VARCHAR(10)
);

-- Transform staging data into final table (fix dates, convert blanks to NULL)
INSERT INTO retail_sales
SELECT 
    transaction_id,
    customer_id,
    category,
    NULLIF(item, ''),
    NULLIF(price_per_unit, '') + 0,
    NULLIF(quantity, '') + 0,
    NULLIF(total_spent, '') + 0,
    payment_method,
    location,
    STR_TO_DATE(transaction_date, '%d-%m-%Y'),
    discount_applied
FROM staging_data;

select * from retail_sales limit 10;

-- ============================================
-- SECTION 3: DATA CLEANING VIEW
-- ============================================
create or replace view cleaned_retail_sales as
select
    transaction_id,
    customer_id,
    category,
    case
        when item is null then 'Unknown Item' else item end as item,
    case
        when price_per_unit is null and quantity is not null and total_spent is not null 
             then total_spent/quantity
        else price_per_unit end as price_per_unit,
    case
        when quantity is null then 'quantity not Found' else quantity
        end as quantity,
    case
        when total_spent is null then 'TS not Found' else total_spent
        end as total_spent,
    payment_method,
    location,
    transaction_date,
    monthname(transaction_date) as month,
    case
        when discount_applied is null or discount_applied = '' then 'Not Recorded'
        when discount_applied = 'TRUE' then 'YES'
        else 'NO' end as discount_applied,
    case
        when quantity is null and total_spent is null then 'qty and TS is missing'
        when item is null then 'Item missing'
        else 'Completed' 
        end as data_quality_flag
from retail_sales;

select * from cleaned_retail_sales;

-- ============================================
-- SECTION 4: ANALYSIS QUERIES
-- ============================================

-- 1. Revenue by Category
select category, sum(total_spent) as Total_revenue, count(*) as Total_order
from cleaned_retail_sales
group by category;

-- 2. Revenue by Location
select location, sum(total_spent) as Total_revenue
from cleaned_retail_sales
group by location;

-- 3. Revenue by Payment Method
select payment_method, sum(total_spent) as Total_revenue 
from cleaned_retail_sales
group by payment_method
order by Total_revenue desc;

-- 4. Month-wise Revenue Trend
select month, sum(total_spent) as Total_revenue
from cleaned_retail_sales
group by month
order by min(transaction_date);

-- 5. Discount Impact on Average Order Value    
select discount_applied, avg(total_spent) as Total_order_revenue
from cleaned_retail_sales
group by discount_applied;

-- 6. Top 10 Highest Spending Customers
select customer_id, sum(total_spent) as Total_spent
from cleaned_retail_sales
group by customer_id
order by Total_spent desc
limit 10;

-- ============================================
-- SECTION 5: BONUS / ADVANCED QUERIES
-- ============================================

-- Running total of revenue by month (window function)
SELECT month, SUM(total_spent) AS monthly_revenue,
       SUM(SUM(total_spent)) OVER (ORDER BY MIN(transaction_date)) AS running_total
FROM cleaned_retail_sales
GROUP BY month
ORDER BY MIN(transaction_date);

-- Customers who spent above average
select customer_id, sum(total_spent) as Total_spend
from cleaned_retail_sales
group by customer_id
having Total_spend > (select avg(total_spent) from cleaned_retail_sales);