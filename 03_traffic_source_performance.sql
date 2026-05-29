-- Traffic source performance analysis
-- Measures sessions, purchases, revenue, and purchase rate by source, medium, and campaign

CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.traffic_source_performance` AS

WITH events_base AS (
  SELECT
    user_pseudo_id,
    CONCAT(
      user_pseudo_id,
      '-',
      CAST((
        SELECT value.int_value
        FROM UNNEST(event_params)
        WHERE key = 'ga_session_id'
      ) AS STRING)
    ) AS session_id,
    COALESCE(traffic_source.source, 'unknown') AS source,
    COALESCE(traffic_source.medium, 'unknown') AS medium,
    COALESCE(traffic_source.name, 'unknown') AS campaign,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  source,
  medium,
  campaign,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS total_users,
  COUNT(DISTINCT session_id) AS total_sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(COUNTIF(event_name = 'purchase') / COUNT(DISTINCT session_id) * 100, 2) AS purchase_rate_pct
FROM events_base
GROUP BY
  source,
  medium,
  campaign
ORDER BY total_revenue DESC;