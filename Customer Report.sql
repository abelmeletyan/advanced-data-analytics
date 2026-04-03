create view gold.report_customers AS
with base_sales_customer_table AS
(
-- Base Query: Retrieves core columns from tables
  -- 1. Gathers essential fields such as name, age and transaction details.
	-- SOLUTION: Write base_query with essential fields included.
	select
		s.order_number,
		s.product_key,
		s.order_date,
		year(s.order_date) year_order,
		month(s.order_date) month_order,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		concat(c.first_name, ' ', c.last_name) customer_name,
		c.birthdate,
		datediff(year, c.birthdate, getdate()) age
	from gold.fact_sales s
	left join gold.dim_customers c on s.customer_key = c.customer_key
	where order_date is not null
),
aggregation AS
(
-- Customer aggregations: Summarizes key metrics at the customer level
-- 3. Aggregates customer-level metrics:
--		- total orders
--		- first and last order_date,
--		- total sales
--		- total quantity purchased
--		- total products
--		- lifespan (in months)
	select
		customer_key,
		customer_number,
		customer_name,
		age,
		count(distinct order_number) order_count,
		min(order_date) first_purchase,
		max(order_date) last_purchase,
		datediff(month, min(order_date), max(order_date)) lifespan,
		sum(sales_amount) total_sales,
		sum(quantity) total_quantity,
		count(distinct product_key) total_products
	from base_sales_customer_table
	group by customer_key, customer_number, customer_name, age 
),
final_result AS
(
-- 2. Segments customers into categories (VIP, Regular, New) and age groups.
-- 4. Calculates valuable KPIs:
--		- recency (months since last order)
--		- average order value
--		- average monthly spend
	select
		customer_key,
		customer_number,
		customer_name,
		age,
		order_count,
		first_purchase,
		last_purchase,
		lifespan,
		total_sales,
		total_quantity,
		total_products,
		case
			when lifespan >= 12 and total_sales > 5000 then 'VIP'
			when lifespan >= 12 and total_sales <= 5000 then 'Regular'
			else 'New' end customer_category,
		case
			when age < 20 then 'Under 20'
			when age between 20 and 29 then '20-29'
			when age between 30 and 39 then '30-39'
			when age between 40 and 49 then '40-49'
			else '50 and Above' end age_group,
		datediff(month, last_purchase, getdate()) recency,
		case when order_count = 0 then 0
			else (total_sales / order_count) end avg_order, -- total_sales / total_orders
		case when lifespan = 0 then total_sales
			else total_sales / lifespan end avg_monthly_spend
	from aggregation
)
select * from final_result;