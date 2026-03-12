# Root Module - AWS Account Security Setup
# Orchestrates all security modules in the correct dependency order

# Module 1: SNS Notifications (no dependencies)
# Must be created first as other modules depend on SNS topic ARNs
module "sns_notifications" {
  source = "./modules/sns-notifications"

  account_id            = var.account_id
  aws_region            = var.aws_region
  security_alert_emails = var.security_alert_emails
  budget_alert_emails   = var.budget_alert_emails
  tags                  = var.tags
}

# Module 2: Account Security Policies (no dependencies)
# Sets account-level security configurations
module "account_security" {
  source = "./modules/account-security"

  tags = var.tags
}

# Module 3: CloudTrail (no dependencies on other modules)
# Audit logging for all API calls
module "cloudtrail" {
  source = "./modules/cloudtrail"

  account_id         = var.account_id
  aws_region         = var.aws_region
  log_retention_days = var.cloudtrail_log_retention_days
  tags               = var.tags
}

# Module 4: AWS Budgets (depends on SNS)
# Cost monitoring and alerts
module "budgets" {
  source = "./modules/budgets"

  budget_sns_topic_arn = module.sns_notifications.budget_alerts_topic_arn
  tags                 = var.tags

  # Ensure SNS topics are created first
  depends_on = [module.sns_notifications]
}

# Module 5: IAM Identity Center (no dependencies)
# Centralized access management with SSO
module "iam_identity_center" {
  source = "./modules/iam-identity-center"

  tags = var.tags
}
