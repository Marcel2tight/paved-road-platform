CREATE OR REPLACE VIEW
  `imposing-fx-413205.finops_reporting.v_daily_cost_summary`
AS
SELECT
  usage_date,
  invoice_month,
  project_id,
  project_name,
  project_environment,
  CASE
    WHEN original_environment = "shared" THEN "shared"
    ELSE project_environment
  END AS reporting_environment,
  normalized_platform,
  normalized_service,
  original_owner AS owner,
  original_managed_by AS managed_by,
  billing_service,
  cost_type,
  currency,
  COUNT(*) AS line_items,
  COUNT(DISTINCT resource_name) AS resource_count,
  ROUND(SUM(gross_cost), 6) AS gross_cost,
  ROUND(SUM(credit_amount), 6) AS credit_amount,
  ROUND(SUM(net_cost), 6) AS net_cost,
  ROUND(
    SUM(
      IF(
        has_environment_label
        AND has_service_label
        AND has_ownership_label,
        net_cost,
        0
      )
    ),
    6
  ) AS labeled_net_cost,
  ROUND(
    SUM(
      IF(
        NOT (
          has_environment_label
          AND has_service_label
          AND has_ownership_label
        ),
        net_cost,
        0
      )
    ),
    6
  ) AS unlabeled_net_cost
FROM
  `imposing-fx-413205.finops_reporting.v_billing_normalized`
GROUP BY
  usage_date,
  invoice_month,
  project_id,
  project_name,
  project_environment,
  reporting_environment,
  normalized_platform,
  normalized_service,
  owner,
  managed_by,
  billing_service,
  cost_type,
  currency;
