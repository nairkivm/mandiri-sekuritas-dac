WITH max_tx_date AS (
  SELECT DATE_TRUNC(MAX(DATE(date)), MONTH) AS max_month
  FROM `ms_data.transactions_data`
),

-- Hitung periode terakhir (3 bulan terakhir)
recent_tx AS (
  SELECT
    t.client_id,
    COUNT(t.id) AS txn_count_recent,
    SUM(t.amount) AS txn_amount_recent
  FROM
    `ms_data.transactions_data` t
  CROSS JOIN max_tx_date m
  WHERE DATE(t.date) BETWEEN DATE_SUB(m.max_month, INTERVAL 2 MONTH) AND m.max_month
  GROUP BY t.client_id
),

-- Hitung periode sebelumnya (3 bulan sebelum recent)
baseline_tx AS (
  SELECT
    t.client_id,
    COUNT(t.id) AS txn_count_baseline,
    SUM(t.amount) AS txn_amount_baseline
  FROM
    `ms_data.transactions_data` t
  CROSS JOIN max_tx_date m
  WHERE DATE(t.date) BETWEEN DATE_SUB(m.max_month, INTERVAL 5 MONTH) AND DATE_SUB(m.max_month, INTERVAL 3 MONTH)
  GROUP BY t.client_id
),

-- Gabungkan recent & baseline
compare_tx AS (
  SELECT
    r.client_id,
    r.txn_count_recent,
    b.txn_count_baseline,
    r.txn_amount_recent,
    b.txn_amount_baseline,
    SAFE_DIVIDE(r.txn_count_recent, NULLIF(b.txn_count_baseline,0)) AS ratio_txn_count
  FROM
    recent_tx r
  LEFT JOIN
    baseline_tx b
  ON r.client_id = b.client_id
)

-- Identifikasi potensi churn
SELECT
  u.current_age,
  u.gender,
  u.yearly_income,
  u.total_debt,
  SAFE_DIVIDE(u.total_debt, NULLIF(u.yearly_income,0)) AS debt_to_income_ratio,
  u.credit_score,
  CASE 
    WHEN u.credit_score < 580 THEN 'Poor (<580)'
    WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
    WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
    WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
    ELSE 'Excellent (800+)'
  END AS credit_score_group,
  c.txn_count_baseline,
  c.txn_count_recent,
  ROUND(1 - c.ratio_txn_count, 2) AS percent_drop
FROM
  compare_tx c
JOIN
  `ms_data.users_data` u
ON
  c.client_id = u.id
WHERE
  c.ratio_txn_count < 0.7 -- turun ≥30%
ORDER BY
  c.ratio_txn_count ASC;
