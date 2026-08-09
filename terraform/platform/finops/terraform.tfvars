management_project_id                    = "imposing-fx-413205"
region                                   = "us-central1"
billing_account_id                       = "01500A-A64D6C-AB73C2"
terraform_deployer_service_account_email = "paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"

budget_display_name            = "Paved Road Platform Budget"
monthly_budget_amount          = 50
budget_notification_topic_name = "paved-road-billing-budget-notifications"
budget_consumer_image          = "us-central1-docker.pkg.dev/imposing-fx-413205/paved-road-containers/finops-budget-consumer@sha256:9280fc722ffa8b582d891ef4f89c4e5d5f5b688175534175f4dc5899e2ccab76"