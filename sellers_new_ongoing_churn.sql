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
base_sellers_with_category AS ( -- CLASSIFICAÇÃO DO SELLER
  SELECT
    dates,
    -- min_dates,
    -- max_dates,
    seller_id,
    CASE 
      WHEN min_dates = dates THEN 'new'
      WHEN min_dates < dates AND max_dates >= dates THEN 'ongoing'
      ELSE 'churn'
    END AS seller_category
  FROM base_sellers
  ORDER BY seller_id, dates
),
churn_sellers AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category,
    ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY dates) AS row_num
  FROM base_sellers_with_category
  WHERE seller_category = 'churn'
),
filtered_churn_sellers AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category
  FROM churn_sellers
  WHERE row_num = 1
),
new_and_ongoing_sellers AS (
  SELECT
    dates,
    seller_id,
    seller_category
  FROM base_sellers_with_category
  WHERE seller_category IN ('new', 'ongoing')
),
final_result AS (
  SELECT 
    dates, 
    seller_id, 
    seller_category
  FROM new_and_ongoing_sellers
  UNION ALL
  SELECT 
    dates, 
    seller_id, 
    seller_category
  FROM filtered_churn_sellers
)
SELECT 
  dates,
  seller_category,
  count(distinct seller_id) as count_sellers
FROM final_result
group by 1,2
ORDER BY 1,2;

