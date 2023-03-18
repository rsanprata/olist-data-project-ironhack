-- quantos ao total
-- quantos já venderam via olist
-- quantos ativos no último mês (excluindo setembro 2018)

select *
from sellers s;

select * 
from orders o;

select *
from order_items oi;

-- sellers without completed order
with sellers_without_sales as (
	select 
		distinct s.seller_id,
		case
			when order_status in ('unavailable','canceled') then 1 else 0
		end as without_sales
	from orders o 
	left join order_items oi
		on oi.order_id = o.order_id
	left join sellers s
		on s.seller_id = oi.seller_id
)
-- sellers active (with order in last month)
, active_sellers as (
	select 
		distinct s.seller_id,
		case
			when extract(month from order_purchase_timestamp) = 8
			and extract(year from order_purchase_timestamp) = 2018
			then 1
			else 0
		end as active_sellers
	from orders o 
	left join order_items oi
		on oi.order_id = o.order_id
	left join sellers s
		on s.seller_id = oi.seller_id
	where order_status not in ('unavailable','canceled')
)
select
	count(distinct s.seller_id) as total_sellers,
	count(case when without_sales = 1 then s.seller_id end) as sellers_without_sales,
	count(case when active_sellers = 1 then s.seller_id end) as active_sellers 
from sellers s
left join sellers_without_sales sws
	on sws.seller_id = s.seller_id
left join active_sellers acs
	on acs.seller_id = s.seller_id


