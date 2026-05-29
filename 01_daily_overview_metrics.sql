-- Daily overview metrics for ecommerce performance
-- Source: Google Analytics ecommerce public dataset in BigQuery

CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.daily_overview_metrics` AS

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS event_date,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS total_users,
  COUNT(DISTINCT CONCAT(
    user_pseudo_id,
    '-',
    CAST((
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS STRING)
  )) AS total_sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd), 2) AS total_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_date
ORDER BY event_date;