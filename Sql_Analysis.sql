CREATE DATABASE portfolio;
use portfolio;

-- Customer segmentation on the basis of purchases.

with cte as (
select c.customer_id, c.first_name, sum(il.quantity*il.unit_price) as "Purchases",
CASE WHEN sum(il.quantity*il.unit_price)>80 THEN "High purchase customers"
	 WHEN  sum(il.quantity*il.unit_price)<=80 AND sum(il.quantity*il.unit_price)>50 THEN "Middle purchase customers"
     else "Low purchase customers"
END AS "Customer_segmentation"     
from customer c
join invoice i
on c.customer_id= i.customer_id
join invoice_line il
on i.invoice_id= il.invoice_id
GROUP BY 1,2
)

select Customer_segmentation, count(*) FROM cte
GROUP BY 1;


-- Average amount spent by per customer.
with cte as (
select customer_id, avg(total) as "Avg_value"
from invoice
group by 1)

select  ct.customer_id, c.first_name, ct.Avg_value
from cte as ct
join customer as c
on ct.customer_id= c.customer_id


-- Which city has best customers.  We like to throw a concert where we can make most money.
-- Find the city of customers who have highest sum of total invoices.

select billing_city, sum(total)
FROM invoice
GROUP BY 1
ORDER BY  sum(total) DESC
limit 1;

select billing_state, sum(total)
FROM invoice
GROUP BY 1
ORDER BY  sum(total) DESC;



-- Who is the best customer. Customer who spent most money

select c.customer_id,c.first_name,c.last_name, sum(i.total)
FROM invoice i
JOIN customer c
on c.customer_id=i.customer_id
GROUP BY  c.customer_id,c.first_name,c.last_name
order by sum(i.total) DESC
LIMIT 1;



-- Customers who spent the max amount from each country.

WITH CTE1 AS (
select  c.first_name,C.last_name, c.country, sum(il.quantity*il.unit_price) as "Purchases"
from customer c
join invoice i
on c.customer_id= i.customer_id
join invoice_line il
on i.invoice_id=il.invoice_id
GROUP BY 1,2,3),

cte2 as (
Select*,
row_number() over(partition by country order by Purchases desc) as "Rnk"
FROM cte1)

select *from cte2 where rnk=1;


-- Which genre of music customers like the most

WITH CTE AS (
select i.customer_id,t.genre_id, g.name
from invoice i
join invoice_line il
on i.invoice_id=il.invoice_id
join track t
on il.track_id=t.track_id
join genre g
on g.genre_id= t.genre_id)

SELECT name,count(*) AS "genre listners"
FROM CTE
GROUP BY 1
ORDER BY count(*) desc;

-- Repeat and new customers.
with cte as (
select c.customer_id,i.invoice_id, c.first_name, c.state, i.invoice_date_format
from customer as c
join invoice as i
on c.customer_id=i.customer_id
),

new_cust as (
select customer_id, first_name, min(invoice_date_format) as "min_date"
from cte
group by 1,2),

rep_cust as ( 
select c.customer_id, c.first_name,c.invoice_date_format, nc.min_date
from cte as c
join new_cust as nc
on c.customer_id= nc.customer_id
),

reten_rate as (
select x.customer_id,x.first_name,x.invoice_date_format, x.min_date,
CASE WHEN x.invoice_date_format=x.min_date THEN "new_customers" ELSE "repeat_customers" end as "customers_type"
from rep_cust as x)

select customers_type, count(*)
from  reten_rate
group by 1

-- 555 customers were repeated in stores to buy music.


-- Conclusion

-- PRAGUE city has the best customers in terms of Purchase of tracks. This city
-- was good enough to hold the concert.

-- USA country customers buys the most product.

-- Customers like the Rock Genre music. Store should keep the stock of Rock music.

-- Customer segmentation on the basis of purchases. Mostly customers spend between 80$ to 50$.and
-- Count of new customers and Repeated customers.






