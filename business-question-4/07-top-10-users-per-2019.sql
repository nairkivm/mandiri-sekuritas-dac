WITH user_txn_2019 AS (
  SELECT
    t.client_id,
    SUM(t.amount) AS total_amount,
    COUNT(t.id) AS total_transactions
  FROM
    `ms_data.transactions_data` t
  WHERE
    EXTRACT(YEAR FROM DATE(t.date)) <= 2019
  GROUP BY
    t.client_id
),
ranked_users AS (
  SELECT
    client_id,
    total_amount,
    total_transactions,
    PERCENT_RANK() OVER (ORDER BY total_amount DESC) AS pr
  FROM
    user_txn_2019
),
top_users AS (
  SELECT r.client_id, r.total_amount, r.total_transactions, u.current_age, u.yearly_income, u.credit_score
  FROM ranked_users r
  JOIN `ms_data.users_data` u
    ON r.client_id = u.id
  WHERE r.pr <= 0.10  -- top 10% users
)
SELECT
  CASE 
    WHEN current_age < 25 THEN '<25'
    WHEN current_age BETWEEN 25 AND 40 THEN '25-40'
    WHEN current_age BETWEEN 41 AND 60 THEN '41-60'
    ELSE '>60'
  END AS age_group,
  CASE 
    WHEN yearly_income < 15000 THEN 'Low (<15K)'
    WHEN yearly_income BETWEEN 15000 AND 50000 THEN 'Lower-Middle (15K-50K)'
    WHEN yearly_income BETWEEN 50000 AND 100000 THEN 'Upper-Middle (50K-100K)'
    ELSE 'High (>100K)'
  END AS income_group,
  CASE 
    WHEN credit_score < 580 THEN 'Poor (<580)'
    WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
    WHEN credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
    WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
    ELSE 'Excellent (800+)'
  END AS credit_score_group,
  COUNT(*) AS total_users,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_users,
  ROUND(SUM(total_amount),2) AS total_amount,
  ROUND(SUM(total_amount) * 100.0 / SUM(SUM(total_amount)) OVER (),2) AS percentage_amount
FROM
  top_users
GROUP BY
  age_group, income_group, credit_score_group
ORDER BY
  percentage_amount DESC;
