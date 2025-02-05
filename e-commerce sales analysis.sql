create database cv;
use cv;

-- RFM (Recency, Frequency, Moanetary Value) analysis is done to understand the type of customers.
create view RFM as (
with cte as (
select lo.Order_ID, lo.Order_Date, lo.customerName, lo.State, lo.city, od.Amount
from list_of_orders lo
join order_details od
on lo.Order_ID= od.Order_ID
)

select customerName, max(str_to_date(order_Date, "%d-%m-%Y")) as "Latest_pur_date",
datediff(str_to_date("31-03-2019","%d-%m-%Y"),max(str_to_date(order_Date, "%d-%m-%Y"))) as "Recency",
count(distinct Order_ID) as "Frequency", sum(Amount) as "Value"
FROM CTE
group by 1);


create view cust_category as (
with cte as(
select *, case when Recency>=0 and Frequency<=10 and Value>=2500 then "Loyal and Good customers"
			   when Recency>=0 and Frequency<=10 and Value<=2500 and Value>1000 then "Potential loyal Customers"
               when Recency>=0 and Frequency<=10 and Value<=1000 and Value>100 then "Customer need attention"
			   when Recency>10 and Recency<150 then "Customer need attention"
               when Recency>=150 and Recency<250 then "Customer can be lost"
               when Recency>=250  then "Customer lost"
           end as "Customer_segmentation"
from rfm)

select customer_segmentation, count(customer_segmentation) as "Type of customers",
(count(customer_segmentation)/(select COUNT(*) from RFM)*100) as "Percent of customers"
from cte
group by 1);

select * from RFM; 
select * from cust_category;

-- 15 % are loyal customers and approx 28% are potential loyal. These are best customers for to introduced new produts or schemes.


-- Month on Month growth rate tells us that which month done good in terms of sales.alter
with cte as (
select date_format(str_to_date(lo.Order_Date, "%d-%m-%Y"), "%Y_%m") as "Year-month", count(*) as "Total_orders", sum(od.amount) as "Total_sales"
from list_of_orders lo
join order_details od
on lo.order_id= od.order_id
group by 1
order by "Year_Month" asc),

cte_2 as (
select*, 
lag(Total_sales) over(order by "Year-month" asc) as "last_month_sales"
from cte)

select *,round(((Total_sales-last_month_sales)/Total_sales)*100,2) as "Percent growth"
from cte_2;

-- Demographics analysis shows that customers from cities like indore, mumbai, pune spend much amount on purchase.
-- Seller should target above state and cities for selling the items.

select lo.State, lo.city, sum(od.amount) as "Total_amount", sum(od.quantity) as "Total_quantity"
from list_of_orders lo
join order_details od
on lo.order_id=od.order_id
group by 1,2
order by Total_amount desc

 -- Sale vs Target categorization. It tells whether salespeople achieved theie target or not.
 
create view target_sale as (
with cte as (
select lo.Order_Date, od.Category, sum(od.amount) as "sales"
from list_of_orders lo
join order_details od
on lo.order_id= od.order_id
group by 1,2
),

cte_2 as (
select category, CONCAT(SUBSTR(date_format(str_to_date(Order_Date, "%d-%m-%Y"),"%M"),1,3),"-",SUBSTR(Year(str_to_date(Order_Date, "%d-%m-%Y")),3,4)) as "month_year",
sum(sales) as "sales_category_wise"
from cte
group by 1,2)

select c.category, c.month_year, c.sales_category_wise,st.Target,
case when c.sales_category_wise>st.Target then "Target completed" else "Not_completed" end as "Target_completed_or_not"
from cte_2 c
join sales_target st
on c.category=st.category and c.month_year=st.Month_of_Order_Date)

select*from target_sale
select Target_completed_or_not, count(*)
from target_sale
group by 1

-- Ranked the top 3 sub-categories on the basis of sales. It analyses that which sub_category
-- having the good sales in each category.

with cte as (
select c.category, c.sub_category,c.sales,
rank() over(partition by c.category order by c.sales desc) as "Rank_of_prod"
from (
select category, sub_category,sum(amount) as "sales"
from order_details
group by 1,2
) as c)

select * from cte where Rank_of_Prod<=3

select*from top_cities

-- Top states and thier cities in terms of sales amount.

create view top_cities as (
with cte as (
select lo.State, lo.city, sum(od.sales_per_order) as "City_wise_sales"
from list_of_orders lo
join (select order_ID, sum(amount)  as "sales_per_order"from order_details group by 1) od
on lo.order_id= od.order_id
group by 1,2),

cte_2 as (
select *,
rank() over(partition by state order by City_wise_sales desc) as "rnk" from cte)

select *, ((city_wise_sales/(select sum(amount) from order_details))*100) as "percent_sales" from cte_2)