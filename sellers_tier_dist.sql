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
, seller_agg as (
	select
		-- dates,
		seller_id,
		sum(count_orders) as count_orders,
		sum(sum_sales) as sum_sales,
		avg(avg_price) as avg_price,
		count(distinct dates) as active_months
	from sellers_orders_price sop
	group by 1
)
, seller_tier_ind as (
	select
		seller_id,
		round(count_orders/active_months,1) as monthly_orders,
		round(sum_sales/active_months,2) as monthly_sales,
		round(avg_price,2) as avg_price,
		active_months
	from seller_agg
)
select
	seller_id,
	monthly_orders,
	monthly_sales,
	avg_price,
	case
		when monthly_sales <= 1000 then 'small_seller'
		when monthly_sales > 1000
			and monthly_sales < 5000 then 'medium_seller'
		when monthly_sales > 5000 then 'big seller'
	end as seller_tier
from seller_tier_ind