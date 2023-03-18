-- quero saber quantos sellers vendem a category beleza_saude
-- por mês e ano

with table_etc as (
select -- cada linha é um pedido de um produto, com infos do vendedor e data da compra
	year(o.order_purchase_timestamp) as year_sales,
	month(o.order_purchase_timestamp) as month_sales,
	s.seller_id ,
	s.seller_city ,
	s.seller_state ,
	p.product_category_name ,
	round(sum(oi.price),2) as revenue
from order_items oi -- puxo todas os pedidos
left join sellers s -- adiciono o id do seller
	on s.seller_id = oi.seller_id 	
left join products p 
	on oi.product_id = p.product_id
left join orders o 
	on oi.order_id = o.order_id 
where o.order_status = "delivered" -- apenas pedidos completos
and year(order_purchase_timestamp) in("2017","2018")
group by 1,2,3,4,5,6
order by 3,1,2,6,7 desc
)
select
	seller_id,
	case when product_category_name = "beleza_saude" then 1 else 0 end as has_beleza_saude,
	count(distinct product_category_name) as count_categories,
	sum(revenue) as revenue,
	group_concat(product_category_name) as categories
from table_etc
group by 1,2

