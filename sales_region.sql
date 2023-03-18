
select
	customer_state as state,
	customer_city as city,
	round(sum(price),2) as revenue
from order_items oi
left join orders o
	on oi.order_id = o.order_id
left join products p 
	on oi.product_id = p.product_id
left join customers c 
	on o.customer_id = c.customer_id
where year(order_purchase_timestamp) in('2017','2018')
group by 1,2
order by 1,2
