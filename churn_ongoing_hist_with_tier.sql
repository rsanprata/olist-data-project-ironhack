WITH dates AS (
  SELECT DISTINCT
    date_format(order_purchase_timestamp, '%Y-%m') AS dates
  FROM orders o 
  WHERE date_format(order_purchase_timestamp, '%Y-%m') NOT IN ('2016-09','2016-10','2016-12','2018-09','2018-10')
),
min_and_max AS (
  SELECT DISTINCT
    s.seller_id,
    MIN(date_format(order_purchase_timestamp, '%Y-%m')) OVER(PARTITION BY s.seller_id) AS min_dates,
    MAX(date_format(order_purchase_timestamp, '%Y-%m')) OVER(PARTITION BY s.seller_id) AS max_dates
  FROM orders o 
  LEFT JOIN order_items oi 
    ON oi.order_id = o.order_id 
  LEFT JOIN sellers s 
    ON s.seller_id = oi.seller_id
  WHERE date_format(date(order_purchase_timestamp), '%Y-%m') NOT IN ('2016-09','2016-10','2016-12','2018-09','2018-10')
    AND s.seller_id IS NOT NULL
),
base_sellers AS (
  SELECT
    dates,
    min_dates,
    max_dates,
    seller_id
  FROM dates dt
  LEFT JOIN min_and_max
    ON left(CAST(min_dates AS CHAR),2) = left(CAST(dates AS CHAR),2) -- gambiarra para fazer o join nas datas
  WHERE min_dates <= dates -- só preencher com seller que entrou no mês ou após
),
-- ------------------------------------- SELLER TIER ---------------------------------------------
sellers_orders_price as (
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
, seller_tier_classif as (
	select
		seller_id,
		monthly_orders,
		monthly_sales,
		avg_price,
		active_months,
		case
			when monthly_sales <= 1000 then 'small_seller'
			when monthly_sales > 1000
				and monthly_sales < 5000 then 'medium_seller'
			when monthly_sales > 5000 then 'big seller'
		end as seller_tier
	from seller_tier_ind
),
-- -------------------------------------------------------------------------------------------------------
base_sellers_with_category AS ( -- CLASSIFICAÇÃO DO SELLER
  SELECT
    dates,
    bs.seller_id,
    CASE 
      WHEN min_dates = dates THEN 'new'
      WHEN min_dates < dates AND max_dates >= dates THEN 'ongoing'
      ELSE 'churn'
    END AS seller_category,
    seller_tier
  FROM base_sellers bs
  left join seller_tier_classif stc
  	on stc.seller_id = bs.seller_id
  ORDER BY seller_id, dates
),
churn_sellers AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category,
    seller_tier,
    ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY dates) AS row_num
  FROM base_sellers_with_category
  WHERE seller_category = 'churn'
),
filtered_churn_sellers AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category,
    seller_tier
  FROM churn_sellers
  WHERE row_num = 1
),
new_and_ongoing_sellers AS (
  SELECT
    dates,
    seller_id,
    seller_category,
    seller_tier
  FROM base_sellers_with_category
  WHERE seller_category IN ('new', 'ongoing')
),
final_result AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category,
    seller_tier
  FROM new_and_ongoing_sellers
  UNION ALL
  SELECT 
    dates, 
    seller_id, 
    seller_category,
    seller_tier
  FROM filtered_churn_sellers
)
SELECT 
  dates,
  seller_category,
  seller_tier,
  count(distinct seller_id) as count_sellers
FROM final_result
group by 1,2,3
ORDER BY 1,2,3;