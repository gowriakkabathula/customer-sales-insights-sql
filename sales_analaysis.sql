
use Retail_Sales_Analysis;

----Table 1

select *
from customers_data;

---#Checking of duplicates

select *,
	ROW_NUMBER() over(partition by customer_id,customer_unique_id
	order by [customer_id] ) as row_num
from customers_data;

with duplicate_cte as 
(select *,
	ROW_NUMBER() over(partition by customer_id,customer_unique_id
	order by [customer_id] ) as row_num
from customers_data
)
select *
from duplicate_cte
where [row_num] > 1;

select *
from customers_data 
where customer_id is null;

----No Missing and Null Values
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---Table 2
select *
from order_items_data;

---Checking duplicates

select order_id, COUNT(*) as duplicates
from order_items_data 
group by order_id
having count(*) > 1;


---Removing Duplicates
WITH duplicate_cte AS
(
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY order_id, product_id, seller_id
        ORDER BY order_id
    ) AS row_num
    FROM order_items_data
)
DELETE FROM duplicate_cte
WHERE row_num > 1;

---Handling Null Values

select *
from order_items_data
where order_id is null;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---Table 3

select * 
from order_payments_data;

---Checking Duplicates

select order_id, count(*)
from order_payments_data
group by order_id
having count(*) > 1;

---Removing duplicates

with duplicate_cte as
(select *,
ROW_NUMBER() over(partition by order_id
order by order_id ) as row_num
from order_payments_data
)
delete from duplicate_cte 
where row_num > 1;

--- Changing date format

update order_items_data
set shipping_limit_date = TRY_CONVERT(date,shipping_limit_date);

select shipping_limit_date
from order_items_data;

---Changing the data type float to int

alter table order_items_data
alter column price decimal(10,2);

select price
from order_items_data;

alter table order_items_data
alter column  freight_value decimal(10,2);

select freight_value
from order_items_data;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Table 4

select * 
from order_payments_data; 

---Checking nulls

select order_id, count(*)
from order_payments_data
group by order_id
having count(*) > 1; --- No duplicates

--Changing data type to decimal

alter table order_payments_data
alter column payment_value decimal(10,2);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Table 5

select *
from orders_data;

---Checking duplicates

select order_id, count(*)
from orders_data
group by order_id
having count(*) > 1; -- No duplicates

---Handling Missing and Null Values

select *
from orders_data
where order_status = 'unavailable';

select *
from orders_data
where order_status = 'canceled';
--#Ordere delivered dates are null where order status is canceled and unavaliable
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---Table 6

select *
from products_data;

---checking duplicates
select product_id,COUNT(*)
from products_data
group by product_id
having count(*) > 1;  ---No duplicates

---Handling Nulls

select *
from products_data
where product_category_name is null;


update products_data
set product_category_name = 'unknown'
	where product_category_name is null;

update products_data
set product_name_length = '0'
where product_name_length is null;

select *
from products_data
where product_description_length is null;

update products_data
set product_description_length = '0'
where product_description_length is null;

update products_data
set product_photos_qty = '0'
where product_photos_qty is null;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---Created new cleaned tables 

select 
order_id,product_id,price,freight_value
into cleaned_order_items_data
from order_items_data;

select 
customer_id,customer_city,customer_state
into cleaned_customer_data
from customers_data;

select order_id,payment_type,payment_value
into cleaned_order_payment_data
from order_payments_data;

select review_id,order_id,review_score
into cleaned_reviews_data
from order_reviews_data;

select order_id,order_status,customer_id,order_purchase_timestamp,order_delivered_customer_date,order_estimated_delivery_date
into cleaned_orders_data
from orders_data;

select product_id,product_category_name
into cleaned_products_data
from products_data;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---EDA sales analysis

---Total revenue
select sum(payment_value) as total_revenue
from cleaned_order_payment_data;

---Total Revenue by city
select 
c.customer_city,
sum(op.payment_value) as revenue_by_city
from cleaned_orders_data o
join cleaned_customer_data c 
	on o.customer_id = c.customer_id
join cleaned_order_payment_data op
	on o.order_id = op.order_id
group by c.customer_city
order by revenue_by_city desc;
--Insight:
--Revenue analysis by city revealed that a few major cities contribute a large scale of overall revenue.

--- Total Revenue by Product category 
select 
	 cp.product_category_name,
	sum(cop.payment_value) as revenue
from cleaned_order_items_data oi
join cleaned_products_data cp
		on oi.product_id = cp.product_id
join cleaned_order_payment_data cop
		on cop.order_id = oi.order_id
group by product_category_name
order by revenue desc ;
---Insight:
--Product categories with higher revenue can be prioritized for inventory planning and targeted promotions.

---Order Status Distribution
select order_status,count(*) total_orders
from cleaned_orders_data
group by order_status
order by total_orders desc;
---Insight:
--Most orders were significantly higher revenue, while canceled and unavailable orders represent a smaller percentage of transactions.

---Checking how many reviews scored
select review_score,count(*) total_reviews
from cleaned_reviews_data
group by review_score
order by review_score desc;
---Insight:
--Review score analysis showed that higher review ratings (4 & 5) appear more frequently., indicating overall positive customer satisfaction.

---Checking which product scored max reviews
select
cpd.product_category_name,
sum(cor.review_score) review
from cleaned_order_items_data coi
join cleaned_products_data cpd
	on coi.product_id = cpd.product_id
join cleaned_reviews_data cor
	on coi.order_id = cor.order_id
group by product_category_name
order by review desc;

---Product_category wise average reviews 
select
cpd.product_category_name,
avg(cor.review_score) avg_review,
count(cor.review_score) total_review
from cleaned_order_items_data coi
join cleaned_products_data cpd
	on coi.product_id = cpd.product_id
join cleaned_reviews_data cor
	on coi.order_id = cor.order_id
group by product_category_name
order by total_review desc;
---Insight:
--Certain categories achieved high reviews score despite generating lower sales revenue. This suggest potentail oppurtunities for better marketing or product visibility.


---Total Sales by Category
select 
cpd.product_category_name,
sum(coi.price) as total_sales
from cleaned_products_data cpd
join cleaned_order_items_data coi
on coi.product_id = cpd.product_id
group by cpd.product_category_name 
order by total_sales desc;

---Monthly Sales Trend 
select 
FORMAT(cod.order_purchase_timestamp, 'yyyy-MM') as month,
sum(coi.price) as revenue
from cleaned_orders_data cod
join cleaned_order_items_data coi
on cod.order_id = coi.order_id
group by FORMAT(cod.order_purchase_timestamp, 'yyyy-MM')
order by month;
---Insight:
--Montly sales trend analysis showed fluctuations in revenue across different months, indicating seasonal demand patterns and customer purchasing behavior.

---Top 10 Customers
select top 10
coc.customer_id,
sum(cop.payment_value) total_spent
from cleaned_orders_data cod
join cleaned_customer_data coc
on coc.customer_id = cod.customer_id
join cleaned_order_payment_data cop
on cod.order_id = cop.order_id
group by coc.customer_id
order by total_spent desc;
---Insight:
--A small group of customers contribute high spending, highlighting valuable repeat or premium customers.


