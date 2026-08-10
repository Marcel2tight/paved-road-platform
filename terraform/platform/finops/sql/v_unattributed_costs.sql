CREATE OR REPLACE VIEW
  `imposing-fx-413205.finops_reporting.v_unattributed_costs`
AS
SELECT
  usage_date,
  project_id,
  project_name,
  project_environment,
  billing_service,
  sku,
  resource_name,
  resource_location,
  currency,
  CASE
    WHEN billing_service = "Container Registry Vulnerability Scanning"
      THEN "security-scanning"
    WHEN billing_service = "Cloud Key Management Service (KMS)"
      THEN "security-and-encryption"
    WHEN billing_service IN ("Cloud Build", "Cloud Storage")
      AND (
        CONTAINS_SUBSTR(resource_name, "cloudbuild")
        OR resource_name = ""
      )
      THEN "managed-build-infrastructure"
    WHEN billing_service = "Artifact Registry"
      THEN "artifact-management"
    ELSE "unclassified-platform-overhead"
  END AS overhead_category,
  CASE
    WHEN resource_name IS NULL
      OR resource_name IN ("", "resource-name-unavailable")
      THEN FALSE
    ELSE TRUE
  END AS has_identifiable_resource,
  COUNT(*) AS line_items,
  ROUND(SUM(gross_cost), 6) AS gross_cost,
  ROUND(SUM(credit_amount), 6) AS credit_amount,
  ROUND(SUM(net_cost), 6) AS net_cost
FROM
  `imposing-fx-413205.finops_reporting.v_billing_normalized`
WHERE
  NOT (
    has_environment_label
    AND has_service_label
    AND has_ownership_label
  )
GROUP BY
  usage_date,
  project_id,
  project_name,
  project_environment,
  billing_service,
  sku,
  resource_name,
  resource_location,
  currency,
  overhead_category,
  has_identifiable_resource;
