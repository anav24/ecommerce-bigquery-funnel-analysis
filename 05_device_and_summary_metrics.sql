-- Device performance and summary KPI tables
-- Creates device-level metrics, monthly trends, and dashboard KPI totals

CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.device_performance` AS

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
    device.category AS device_category,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  device_category,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS total_users,
  COUNT(DISTINCT session_id) AS total_sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(COUNTIF(event_name = 'purchase') / COUNT(DISTINCT session_id) * 100, 2) AS purchase_rate_pct,
  ROUND(SUM(revenue) / COUNT(DISTINCT session_id), 2) AS revenue_per_session
FROM events_base
GROUP BY device_category
ORDER BY total_revenue DESC;


CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.monthly_summary` AS

SELECT
  FORMAT_DATE('%Y-%m', event_date) AS month,
  SUM(total_events) AS total_events,
  SUM(total_users) AS total_users,
  SUM(total_sessions) AS total_sessions,
  SUM(purchases) AS purchases,
  ROUND(SUM(total_revenue), 2) AS total_revenue,
  ROUND(SUM(purchases) / SUM(total_sessions) * 100, 2) AS purchase_rate_pct,
  ROUND(SUM(total_revenue) / SUM(total_sessions), 2) AS revenue_per_session
FROM `ecommerce-bigquery-analysis.ecommerce_analysis.daily_overview_metrics`
GROUP BY month
ORDER BY month;


CREATE OR REPLACE TABLE `ecommerce-bigquery-analysis.ecommerce_analysis.overall_kpi_summary` AS

SELECT
  SUM(total_events) AS total_events,
  SUM(total_users) AS total_users,
  SUM(total_sessions) AS total_sessions,
  SUM(purchases) AS total_purchases,
  ROUND(SUM(total_revenue), 2) AS total_revenue,
  ROUND(SUM(purchases) / SUM(total_sessions) * 100, 2) AS purchase_rate_pct,
  ROUND(SUM(total_revenue) / SUM(total_sessions), 2) AS revenue_per_session,
  ROUND(SUM(total_revenue) / SUM(purchases), 2) AS average_order_value
FROM `ecommerce-bigquery-analysis.ecommerce_analysis.daily_overview_metrics`;