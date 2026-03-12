# Root Module Outputs

# CloudTrail Outputs
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.cloudtrail.trail_arn
}

output "cloudtrail_id" {
  description = "ID of the CloudTrail trail"
  value       = module.cloudtrail.trail_id
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_name
}

output "cloudtrail_s3_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_arn
}

# SNS Outputs
output "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = module.sns_notifications.security_alerts_topic_arn
}

output "security_alerts_topic_name" {
  description = "Name of the security alerts SNS topic"
  value       = module.sns_notifications.security_alerts_topic_name
}

output "budget_alerts_topic_arn" {
  description = "ARN of the budget alerts SNS topic"
  value       = module.sns_notifications.budget_alerts_topic_arn
}

output "budget_alerts_topic_name" {
  description = "Name of the budget alerts SNS topic"
  value       = module.sns_notifications.budget_alerts_topic_name
}

# IAM Identity Center Outputs
output "admin_permission_set_arn" {
  description = "ARN of the Admin permission set"
  value       = module.iam_identity_center.admin_permission_set_arn
}

output "developer_permission_set_arn" {
  description = "ARN of the Developer permission set"
  value       = module.iam_identity_center.developer_permission_set_arn
}

output "readonly_permission_set_arn" {
  description = "ARN of the ReadOnly permission set"
  value       = module.iam_identity_center.readonly_permission_set_arn
}

output "identity_center_instance_arn" {
  description = "ARN of the IAM Identity Center instance"
  value       = module.iam_identity_center.instance_arn
}

output "identity_store_id" {
  description = "ID of the Identity Store"
  value       = module.iam_identity_center.identity_store_id
}

# Budget Outputs
output "cost_budget_name" {
  description = "Name of the cost budget"
  value       = module.budgets.cost_budget_name
}

output "free_tier_budget_name" {
  description = "Name of the free tier usage budget"
  value       = module.budgets.free_tier_budget_name
}

# Account Security Outputs
output "password_policy_minimum_length" {
  description = "Minimum password length configured"
  value       = module.account_security.password_policy_minimum_length
}

output "s3_public_access_block_enabled" {
  description = "Whether S3 account-level public access block is enabled"
  value = {
    block_public_acls       = module.account_security.s3_block_public_acls
    block_public_policy     = module.account_security.s3_block_public_policy
    ignore_public_acls      = module.account_security.s3_ignore_public_acls
    restrict_public_buckets = module.account_security.s3_restrict_public_buckets
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region              = var.aws_region
    account_id          = var.account_id
    project_name        = var.project_name
    environment         = var.environment
    cloudtrail_enabled  = true
    budgets_configured  = true
    iam_identity_center = true
    security_policies   = true
  }
}
