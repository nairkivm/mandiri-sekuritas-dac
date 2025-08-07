WITH max_tx_date AS (
  SELECT DATE_TRUNC(MAX(DATE(date)), MONTH) AS max_month
  FROM `ms_data.transactions_data`
)

SELECT
  t.mcc,
  md.mcc_description,
  COUNT(id) AS total_transactions,
  SUM(amount) AS total_amount
FROM
  `ms_data.transactions_data` t
LEFT JOIN
  `ms_data.mcc_description` md 
  ON t.mcc = md.mcc
CROSS JOIN 
  max_tx_date m
WHERE
  DATE(t.date) >= DATE_SUB(m.max_month, INTERVAL 2 MONTH) -- 3 months
GROUP BY
  t.mcc,
  md.mcc_description
ORDER BY
  total_transactions DESC;
