/*
===============================================================================================================
Product Report
===============================================================================================================
Purpose:
	- This report consolidates key product metrics and behaviors.

Highlights:
	1. Gathers essential filds such as product name, category, subcategory and cost
	2. Segments products by revenue to identify High-Performsers, Mid_Range or Low_Performers.
	3. Aggreagates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthl revenue
=============================================================================================================
*/
-- use DataWarehouseAnalytics;
-- Base Query: Retrieves core columns from tables
  -- 1. Gathers essential fields such as name, age and transaction details.
	-- SOLUTION: Write base_query with essential fields included.

-- select * from gold.fact_sales;

create view gold.report_products AS
with base_query AS
(
	select
		s.order_number,
		s.order_date,
		s.customer_key,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		s.sales_amount,
		s.quantity,
		p.cost
	from gold.fact_sales s
	left join gold.dim_products p on s.product_key = p.product_key
	where s.order_date is not null
),
-- Customer aggregations: Summarizes key metrics at the customer level
-- 3. Aggregates customer-level metrics:
--		- total orders
--		- first and last order_date,
--		- total sales
--		- total quantity purchased or total_count
--		- total products
--		- lifespan (in months)
aggregation AS
(
	select
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		sum(sales_amount) total_sales,
		sum(quantity) total_quantity,
		count(distinct order_number) total_orders,
		count(customer_key) customer_count,
		count(distinct product_key) total_products,
		min(order_date) first_order,
		max(order_date) last_order,
		datediff(month, min(order_date), max(order_date)) lifespan,
		avg(sales_amount / nullif(quantity,0)) as avg_selling_price
	from base_query
	group by product_key, product_name, category, subcategory, cost
),
product_segment AS
(
	select
		product_key,
		product_name,
		category,
		total_sales,
		total_quantity,
		total_orders,
		total_products,
		first_order,
		last_order,
		lifespan,
		avg_selling_price,
		case
			when total_orders > 1000 and lifespan < 12 then 'Popular product'
			when total_orders > 1000 and lifespan >= 12 then 'Fairly Popular product'
			else 'Product needs attention' end popularity_category,
		case
			when total_sales > 50000 then 'High-Performer'
			when total_sales < 10000 then 'Low-Performer'
			else 'Mid-Range' end Sales_category,
		case
			when total_orders < 100 and lifespan >= 12 then 'Worst Selling Product'
			when total_orders between 100 and 500 and (lifespan >= 12) then 'Better Selling Product'
			else 'Best selling product' end selling_category,
		datediff(month, last_order, getdate()) recency,
		case when total_orders = 0 then 0
			else total_sales / total_orders end as avg_order_revenue,
		case when lifespan = 0 then total_sales
			else total_sales / lifespan end as avg_monthly_revenue
	from aggregation
)
select * from product_segment;

-- drop view gold.report_products;
-- where selling_category = 'Worst Selling product';



-- 2x. Segments products into categories (Cheap, Meadium, Expensive)
-- 2y. Calculate valuable KPIs:
--		- recency (months since last order)
--		- average order revenue (AOR)
--		- average monthly revenue



-- 2. Segments customers into categories (VIP, Regular, New) and age groups.
--		- VIP - Spends $5,000 or more for 12 months
--		- Regular - Spends $5,000 or less for 12 months
--		- New - Less than 12 months
-- 4. Calculates valuable KPIs:
--		- recency (months since last order)
--		- average order value
--		- average monthly spend


