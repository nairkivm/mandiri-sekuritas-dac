WITH max_tx_date AS (
  SELECT DATE_TRUNC(MAX(DATE(date)), MONTH) AS start_date
  FROM `ms_data.transactions_data`
),
recent_users AS (
  SELECT DISTINCT t.client_id
  FROM `ms_data.transactions_data` t
  CROSS JOIN max_tx_date m
  WHERE DATE(t.date) >= DATE_SUB(m.start_date, INTERVAL 6 MONTH)
)

SELECT
  CASE 
    WHEN u.yearly_income < 15000 THEN 'Low (<15K)'
    WHEN u.yearly_income BETWEEN 15000 AND 50000 THEN 'Lower-Middle (15K-50K)'
    WHEN u.yearly_income BETWEEN 50000 AND 100000 THEN 'Upper-Middle (50K-100K)'
    ELSE 'High (>100K)'
  END AS income_group,
  COUNT(DISTINCT u.id) AS total_users,
  ROUND(COUNT(DISTINCT u.id) * 100.0 / SUM(COUNT(DISTINCT u.id)) OVER (), 2) AS percentage
FROM
  recent_users r
JOIN
  `ms_data.users_data` u
ON
  r.client_id = u.id
GROUP BY
  income_group
ORDER BY
  total_users DESC;
