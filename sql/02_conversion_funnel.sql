-- Conversion funnel metrics for ecommerce events
-- Measures users moving from product view to purchase

CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.conversion_funnel` AS

SELECT
  event_name AS funnel_step,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name IN (
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )
GROUP BY event_name
ORDER BY
  CASE event_name
    WHEN 'view_item' THEN 1
    WHEN 'add_to_cart' THEN 2
    WHEN 'begin_checkout' THEN 3
    WHEN 'purchase' THEN 4
  END;


CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.conversion_funnel_rates` AS

WITH funnel AS (
  SELECT
    CASE funnel_step
      WHEN 'view_item' THEN 1
      WHEN 'add_to_cart' THEN 2
      WHEN 'begin_checkout' THEN 3
      WHEN 'purchase' THEN 4
    END AS step_order,
    funnel_step,
    unique_users
  FROM `ecommerce-bigquery-analysis.ecommerce_analysis.conversion_funnel`
),

funnel_with_rates AS (
  SELECT
    step_order,
    funnel_step,
    unique_users,
    FIRST_VALUE(unique_users) OVER (ORDER BY step_order) AS starting_users,
    LAG(unique_users) OVER (ORDER BY step_order) AS previous_step_users
  FROM funnel
)

SELECT
  step_order,
  funnel_step,
  unique_users,
  ROUND(unique_users / starting_users * 100, 2) AS conversion_from_start_pct,
  ROUND(unique_users / previous_step_users * 100, 2) AS conversion_from_previous_step_pct,
  ROUND((1 - unique_users / previous_step_users) * 100, 2) AS dropoff_from_previous_step_pct
FROM funnel_with_rates
ORDER BY step_order;
