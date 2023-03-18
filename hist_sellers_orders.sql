-- contagem de vendedores ativos e média de vendas mensal
with data_sellers as ( 
	select
		date_format(order_purchase_timestamp, '%Y-%m') as 'year_month',
		count(distinct oi.seller_id) as count_sellers,
		round(sum(price)/count(distinct oi.seller_id),2) as avg_sales
	from orders o 
	left join order_items oi 
		on oi.order_id = o.order_id
	left join sellers s 
		on s.seller_id = oi.seller_id 
	where
		date_format(order_purchase_timestamp, '%Y-%m')
		not in ('2016-09','2016-10','2016-12','2018-09','2018-10')
		and order_status not in ('canceled','unavailable')
	group by 1
)
-- 
-- contagem de pedidos completos e ticket médio por pedido
-- 
, data_orders as (
	select
		date_format(order_purchase_timestamp, '%Y-%m') as 'year_month',
		count(distinct o.order_id) as count_orders,
		round(sum(price)/count(distinct o.order_id),2) as avg_ticket
	from orders o 
	left join order_items oi 
		on oi.order_id = o.order_id
	where
		date_format(order_purchase_timestamp, '%Y-%m')
		not in ('2016-09','2016-10','2016-12','2018-09','2018-10')
		and order_status not in ('canceled','unavailable')
	group by 1
)
-- 
-- junção das bases pela data
-- 
select *
from data_sellers ds
left join data_orders do
	on do.year_month = ds.year_month