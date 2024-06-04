---- 1. Customer Analysis
-- Customer Segmentation by Number of Orders
WITH customer_segments AS (
    SELECT
        c.customer_id,
        c.company_name,
        c.contact_name,
        c.contact_title,
        c.city,
        c.country,
        COUNT(o.order_id) AS order_count,
        CASE
            WHEN COUNT(o.order_id) <= 5 THEN 'Düşük'
            WHEN COUNT(o.order_id) <= 10 THEN 'Orta'
            ELSE 'Yüksek'
        END AS order_segment
    FROM
        customers c
    LEFT JOIN
        orders o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id,
        c.company_name,
        c.contact_name,
        c.contact_title,
        c.address,
        c.city,
        c.postal_code,
        c.country
)

SELECT
    *,
    CASE
        WHEN order_segment = 'Düşük' THEN 'unloyal customer'
        WHEN order_segment = 'Orta' THEN 'potential customer'
        ELSE 'loyal customer'
    END AS segment_name
FROM
    customer_segments
ORDER BY
    order_count DESC;
-----------------------------------------------

-----------------
---Total number of orders by customer_id
select c.customer_id, Sum(od.quantity) as count_of_order
from customers as c
JOIN orders as o ON c.customer_id = o.customer_id
JOIN order_details as od ON o.order_id = od.order_id
group by c.customer_id
order by count_of_order desc
------------------
--Geographic Segmentation of Customers
SELECT
    c.customer_id,
	c.country,
    c.city,
    COUNT(o.order_id) AS order_count
FROM
    customers c
LEFT JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
	c.city,
    c.country
ORDER BY
    c.country,
    c.city;
-----------------------------------
SELECT
    c.customer_id,
    c.company_name,
    SUM(od.discount) AS total_discount
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_details od ON o.order_id = od.order_id
GROUP BY
    c.customer_id,
    c.company_name
ORDER BY
    total_discount DESC
-------------------
2.-- Discount ve Sales Analysis
--Total Discount Rate Analysis
SELECT
    SUM(od.discount) AS total_discount,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(*) AS total_orders,
    SUM(od.discount) / COUNT(DISTINCT o.customer_id) AS average_discount_per_customer,
    SUM(od.discount) / COUNT(*) AS average_discount_per_order
FROM
    orders o
JOIN
    order_details od ON o.order_id = od.order_id;

----Product Based Discount Rates Analysis:
SELECT
    od.product_id,
    p.product_name,
    AVG(od.discount) AS average_discount,
    AVG(od.discount / (od.unit_price * od.quantity)) * 100 AS discount_rate
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
GROUP BY
    od.product_id, p.product_name
ORDER BY
    discount_rate DESC;
------Discounted and non-discounted sales rates
SELECT
    p.product_id,
	c.category_name,
	p.product_name,
    SUM(CASE WHEN od.discount > 0 THEN od.quantity ELSE 0 END) AS discounted_sales_quantity,
    SUM(CASE WHEN od.discount = 0 THEN od.quantity ELSE 0 END) AS non_discounted_sales_quantity,
    (SUM(CASE WHEN od.discount > 0 THEN od.quantity ELSE 0 END) * 100.0 / NULLIF(SUM(od.quantity), 0)) AS discounted_sales_rate,
    (SUM(CASE WHEN od.discount = 0 THEN od.quantity ELSE 0 END) * 100.0 / NULLIF(SUM(od.quantity), 0)) AS non_discounted_sales_rate
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
JOIN
    categories c ON p.category_id = c.category_id
GROUP BY
    p.product_id, p.product_name, c.category_name
ORDER BY
    p.product_id;
	
------------------------
WITH discount_usage AS (
    SELECT
        o.customer_id,
        COUNT(*) AS discount_usage_count,
        SUM(od.discount) AS total_discount_amount,
        COUNT(DISTINCT o.order_id) AS total_order_count
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
    GROUP BY
        o.customer_id
)
SELECT
    c.customer_id,
    c.company_name,
    coalesce(d.discount_usage_count, 0) AS discount_usage_count,
    coalesce(d.total_discount_amount, 0) AS total_discount_amount,
    coalesce(d.total_order_count, 0) AS total_order_count
FROM
    customers c
LEFT JOIN
    discount_usage d ON c.customer_id = d.customer_id
ORDER BY
    d.total_discount_amount DESC;
--------------------------------
----Discount and order rate per customer
WITH discount_usage AS (
    SELECT
        c.customer_id,
        COUNT(*) AS usage_count,
        SUM(od.discount) AS total_discount_amount
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        order_details od ON o.order_id = od.order_id
    WHERE
        od.discount > 0
    GROUP BY
        c.customer_id
),
order_counts AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS total_order_count
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id
)
SELECT
    c.customer_id,
    c.company_name,
    coalesce(du.usage_count, 0) AS discount_usage_count,
    coalesce(du.total_discount_amount, 0) AS total_discount_amount,
    coalesce(oc.total_order_count, 0) AS total_order_count
FROM
    customers c
LEFT JOIN
    discount_usage du ON c.customer_id = du.customer_id
LEFT JOIN
    order_counts oc ON c.customer_id = oc.customer_id
ORDER BY
    coalesce(du.usage_count, 0) DESC;

--2.Discount and order rate per customer


WITH discount_usage AS (
    SELECT
        c.customer_id,
        COUNT(*) AS usage_count,
        SUM(od.discount) AS total_discount_amount
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        order_details od ON o.order_id = od.order_id
    WHERE
        od.discount > 0
    GROUP BY
        c.customer_id
),
order_counts AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS total_order_count
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id
),
total_revenue AS (
    SELECT
        c.customer_id,
        SUM(od.unit_price * od.quantity * (1 - od.discount)::numeric) AS total_revenue
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN
        order_details od ON o.order_id = od.order_id
    GROUP BY
        c.customer_id
)
SELECT
    c.customer_id,
    c.company_name,
    COALESCE(du.usage_count, 0) AS discount_usage_count,
    COALESCE(du.total_discount_amount, 0) AS total_discount_amount,
    COALESCE(oc.total_order_count, 0) AS total_order_count,
    COALESCE(tr.total_revenue, 0) AS total_revenue
FROM
    customers c
LEFT JOIN
    discount_usage du ON c.customer_id = du.customer_id
LEFT JOIN
    order_counts oc ON c.customer_id = oc.customer_id
LEFT JOIN
    total_revenue tr ON c.customer_id = tr.customer_id
ORDER BY
    COALESCE(du.usage_count, 0) DESC;
	
--------------------RFM Analysis
CREATE TABLE rfm_segment_table AS
WITH recency AS (
    SELECT
        customer_id,
        MAX(order_date)::date AS last_order_date,
        '1998-05-06'::date - MAX(order_date)::date AS recency
    FROM
        orders
    WHERE
        customer_id IS NOT NULL
    GROUP BY
        customer_id
),
frequency AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS frequency
    FROM
        orders
    GROUP BY
        customer_id
),
monetary AS (
    SELECT
        customer_id,
        ROUND(SUM(unit_price * quantity)::numeric, 2) AS monetary
    FROM
        orders
    JOIN
        order_details ON orders.order_id = order_details.order_id
    GROUP BY
        customer_id
),
rfm_data AS (
    SELECT
        r.customer_id,
        r.recency,
        f.frequency,
        m.monetary
    FROM
        recency r
    JOIN
        frequency f ON r.customer_id = f.customer_id
    JOIN
        monetary m ON r.customer_id = m.customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        CASE
            WHEN recency <= 30 THEN 5
            WHEN recency <= 90 THEN 4
            WHEN recency <= 180 THEN 3
            ELSE 2
        END AS recency_score,
        CASE
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 5 THEN 3
            ELSE 5
        END AS frequency_score,
        CASE
            WHEN monetary <= 1000 THEN 2
            WHEN monetary <= 5000 THEN 3
            ELSE 5
        END AS monetary_score
    FROM
        rfm_data
),
rfm_segment AS (
    SELECT
        customer_id,
        recency_score,
        frequency_score,
        monetary_score,
        recency_score + frequency_score + monetary_score AS rfm_score,
        CASE
            WHEN recency_score + frequency_score + monetary_score >= 12 THEN 'VIP Customer'
            WHEN recency_score + frequency_score + monetary_score >= 9 THEN 'Gold Customer'
            WHEN recency_score + frequency_score + monetary_score BETWEEN 6 AND 8 THEN 'Silver Customer'
            ELSE 'Bronze Customer'
        END AS segment
    FROM
        rfm_scores
)
SELECT * FROM rfm_segment;
-----
SELECT *
FROM rfm_segment_table
ORDER BY rfm_score DESC
LIMIT 5;

----------- Top 5 most ordered products
WITH ProductSales AS (
    SELECT
    p.product_id ,   
	p.product_name,
        c.category_name,
        SUM(od.quantity) AS TotalSales
    FROM
        order_details AS od
    INNER JOIN
        Products p ON od.product_id = p.product_id
	JOIN categories as c ON c.category_id = p.category_id
    GROUP BY
    p.product_id,    
	p.product_name,
        c.category_name
)
SELECT
    ps.product_id,
    ps.product_name,
    ps.category_name,
    ps.TotalSales
FROM
    ProductSales ps
ORDER BY
    ps.TotalSales DESC
LIMIT 5;


---------------5 Products That Generate the Most Returns
WITH ProductRevenue AS (
    SELECT
    p.product_id,    
	p.product_name,
        c.category_name,
        Round(SUM(od.quantity * od.unit_price)::Numeric,2) AS TotalRevenue
    FROM
        order_details AS od
    INNER JOIN
        products AS p ON od.product_id = p.product_id
	JOIN categories as c ON c.category_id = p.category_id
    GROUP BY
    p.product_id,    
	p.product_name,
        c.category_name
)
SELECT
    pr.product_id,
    pr.product_name,
    pr.category_name,
    pr.TotalRevenue
FROM
    ProductRevenue pr
ORDER BY
    pr.TotalRevenue DESC
LIMIT 5;

-----Product categories with the most discounts
WITH DiscountPerCategory AS (
    SELECT
	p.product_id,    
	p.product_name,
        c.category_name,
        SUM(od.discount) AS TotalDiscount
    FROM
        order_details AS od
    INNER JOIN
        products AS p ON od.product_id = p.product_id
	JOIN categories as c ON c.category_id = p.category_id
    WHERE
        od.discount > 0
    GROUP BY
        c.category_name,p.product_id,p.product_name
)
SELECT
    product_id,
    product_name,
	category_name,
    TotalDiscount
FROM
    DiscountPerCategory
ORDER BY
    TotalDiscount DESC
	LIMIT 5

----Count of Products by Supplier
SELECT
    p.supplier_id,
    s.company_name,
	Count(DISTINCT p.product_id) AS count_of_products_supplied
FROM
    products AS p
INNER JOIN
    Suppliers s ON p.supplier_id = s.supplier_id
GROUP BY
    p.supplier_id,
    s.company_name
Order By count_of_products_supplied DESC
-----Count of Orders by Countries
Select c.country, SUM(od.quantity) AS orders_by_country 
From customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
JOIN order_details AS od ON o.order_id = od.order_id
GROUP BY c.country
ORDRR By orders_by_country DESC
--------Count of Orders by Category
SELECT c.category_name, Sum(od.quantity)AS sales_by_category FROM categories AS c
JOIN products AS p ON c.category_id = p.category_id
JOIN order_details AS od ON od.product_id = p.product_id
GROUP BY category_name
ORDER BY sales_by_category DESC

------------Order Count by 1996
SELECT o.order_date, SUM(od.quantity) AS TotalSales1996
FROM order_details as od
JOIN orders as o ON o.order_id = od.order_id
WHERE EXTRACT(Year FROM order_date) = 1996
GROUP BY order_date
ORDER BY order_date ASC
------------------Net Income by 1998
SELECT o.order_date, 
CAST(SUM(od.quantity * od.unit_price * (1 - od.discount)) 
	 AS NUMERIC(10, 2)) AS TotalIncome1996
FROM order_details AS od
JOIN orders AS o ON o.order_id = od.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 1998
GROUP BY o.order_date
ORDER BY o.order_date ASC