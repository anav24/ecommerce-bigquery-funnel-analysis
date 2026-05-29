-- Product performance analysis
-- Groups by item_name because item IDs are inconsistent across view and purchase events in the sample dataset

CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.product_performance` AS

WITH product_events AS (
  SELECT
    item.item_name,
    event_name,
    item.quantity,
    item.item_revenue_in_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN (
      'view_item',
      'add_to_cart',
      'purchase'
    )
)

SELECT
  item_name,
  COUNTIF(event_name = 'view_item') AS product_views,
  COUNTIF(event_name = 'add_to_cart') AS add_to_carts,
  COUNTIF(event_name = 'purchase') AS purchases,
  SUM(CASE WHEN event_name = 'purchase' THEN quantity ELSE 0 END) AS units_purchased,
  ROUND(SUM(COALESCE(item_revenue_in_usd, 0)), 2) AS product_revenue,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'add_to_cart'), COUNTIF(event_name = 'view_item')) * 100, 2) AS view_to_cart_rate_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'purchase'), COUNTIF(event_name = 'add_to_cart')) * 100, 2) AS cart_to_purchase_rate_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'purchase'), COUNTIF(event_name = 'view_item')) * 100, 2) AS view_to_purchase_rate_pct
FROM product_events
WHERE item_name IS NOT NULL
GROUP BY item_name
ORDER BY product_revenue DESC;


CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.product_opportunities` AS

SELECT
  item_name,
  product_views,
  add_to_carts,
  purchases,
  units_purchased,
  product_revenue,
  view_to_cart_rate_pct,
  cart_to_purchase_rate_pct,
  view_to_purchase_rate_pct
FROM `ecommerce-bigquery-analysis.ecommerce_analysis.product_performance`
WHERE product_views >= 10000
ORDER BY view_to_purchase_rate_pct ASC;
