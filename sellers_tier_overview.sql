-- Volume de vendedores, por agrupamento de sellers (por fat. mensal)
-- count distinct de sellers, por year_month, com seu avg_sales, e distinct customer para quem vendeu

-- count de pedidos e soma de valores por vendedor e data
with sellers_orders_price as (
	select distinct
		date_format(order_purchase_timestamp, '%Y-%m') AS dates,
		s.seller_id,
		count(distinct o.order_id) as count_orders,
		sum(price) as sum_sales,
		round(sum(price)/count(distinct o.order_id)) as avg_price
	from orders o 
	left join order_items oi 
		on oi.order_id = o.order_id 
	left join sellers s 
		on s.seller_id = oi.seller_id
	where
		date_format(order_purchase_timestamp, '%Y-%m')
			not in ('2016-09','2016-10','2016-12','2018-09','2018-10')
		and s.seller_id is not null
	group by 1,2
	order by 2,1
)
-- classification
, seller_classif as (
	select
		dates,
		seller_id,
		count_orders,
		sum_sales,
		avg_price,
		case
			when avg(sum_sales) <= 1000 then 'small_seller'
			when avg(sum_sales) > 1000
				and avg(sum_sales) < 5000 then 'medium_seller'
			when avg(sum_sales) > 5000 then 'big seller'
		end as seller_tier
	from sellers_orders_price sop
	group by 1,2
)
select
	seller_tier,
	count(seller_id) as count_sellers,
	round(avg(count_orders),2) as avg_orders,
	round(avg(avg_price),2) as avg_price
from seller_classif
group by 1
-- order by round(sum_sales/count_orders,2) desc