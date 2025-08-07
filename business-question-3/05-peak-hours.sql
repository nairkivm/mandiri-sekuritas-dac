WITH max_tx_date AS (
  SELECT DATE_TRUNC(MAX(DATE(date)), MONTH) AS max_month
  FROM `ms_data.transactions_data`
),
last_3_months AS (
  SELECT 
    EXTRACT(DAYOFWEEK FROM DATE(t.date)) AS day_of_week, -- 1 = Sunday, 7 = Saturday
    EXTRACT(HOUR FROM TIMESTAMP(t.date)) AS hour_of_day,
    COUNT(t.id) AS total_transactions
  FROM 
    `ms_data.transactions_data` t
  CROSS JOIN 
    max_tx_date m
  WHERE 
    DATE(t.date) >= DATE_SUB(m.max_month, INTERVAL 2 MONTH) -- 3 months = current + 2 previous
  GROUP BY 
    day_of_week, hour_of_day
)

SELECT
  CASE day_of_week
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS day_name,
  hour_of_day,
  total_transactions
FROM
  last_3_months
ORDER BY
  total_transactions DESC
LIMIT 10;
