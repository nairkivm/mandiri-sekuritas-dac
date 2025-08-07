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
    WHEN u.credit_score < 580 THEN 'Poor (<580)'
    WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
    WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
    WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
    ELSE 'Excellent (800+)'
  END AS credit_score_group,
  COUNT(DISTINCT u.id) AS total_users,
  ROUND(COUNT(DISTINCT u.id) * 100.0 / SUM(COUNT(DISTINCT u.id)) OVER (), 2) AS percentage
FROM
  recent_users r
JOIN
  `ms_data.users_data` u
ON
  r.client_id = u.id
GROUP BY
  credit_score_group
ORDER BY
  total_users DESC;
