
select
	product_category_name as category,
	date_format(order_purchase_timestamp, '%m-%Y') as 'month_year',
	count(oi.product_id) as volume_product,
	round(sum(price),2) as sales_product
from order_items oi
left join orders o
on oi.order_id = o.order_id
left join products p 
on oi.product_id = p.product_id 
group by 1,2


