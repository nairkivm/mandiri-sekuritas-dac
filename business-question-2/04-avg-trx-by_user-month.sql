WITH max_tx_date AS (
  SELECT DATE_TRUNC(MAX(DATE(date)), MONTH) AS max_month
  FROM `ms_data.transactions_data`
),
last_12_months AS (
  SELECT 
    t.client_id,
    DATE_TRUNC(DATE(t.date), MONTH) AS txn_month,
    COUNT(t.id) AS txn_count,
    SUM(t.amount) AS txn_amount
  FROM 
    `ms_data.transactions_data` t
  CROSS JOIN 
    max_tx_date m
  WHERE 
    DATE(t.date) >= DATE_SUB(m.max_month, INTERVAL 11 MONTH)
  GROUP BY 
    client_id, txn_month
)

SELECT
  txn_month,
  ROUND(AVG(txn_count), 2) AS avg_txn_per_user,
  ROUND(AVG(txn_amount), 2) AS avg_amount_per_user
FROM
  last_12_months
GROUP BY
  txn_month
ORDER BY
  txn_month;
