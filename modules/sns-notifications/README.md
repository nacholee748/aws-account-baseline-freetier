# SNS Notifications Module

This module creates SNS topics for security and budget alerts with email subscriptions.

## Features

- Creates two SNS topics:
  - `security-alerts`: For security-related notifications (root account usage, IAM changes, etc.)
  - `budget-alerts`: For cost and budget notifications
- Configures email subscriptions for each topic
- Sets up topic policies to allow AWS services (CloudTrail, Budgets, EventBridge) to publish messages
- Applies consistent tagging to all resources

## Usage

```hcl
module "sns_notifications" {
  source = "./modules/sns-notifications"
  
  account_id             = "123456789012"
  aws_region             = "us-east-1"
  security_alert_emails  = ["security@example.com"]
  budget_alert_emails    = ["billing@example.com"]
  
  tags = {
    ManagedBy   = "Terraform"
    Project     = "AWS-Security-Setup"
    Environment = "Production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| security_alert_emails | List of email addresses to receive security alerts | `list(string)` | Yes | - |
| budget_alert_emails | List of email addresses to receive budget alerts | `list(string)` | Yes | - |
| account_id | AWS account ID | `string` | Yes | - |
| aws_region | AWS region for SNS topics | `string` | No | `us-east-1` |
| tags | Common tags to apply to all resources | `map(string)` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| security_alerts_topic_arn | ARN of the security alerts SNS topic |
| security_alerts_topic_name | Name of the security alerts SNS topic |
| budget_alerts_topic_arn | ARN of the budget alerts SNS topic |
| budget_alerts_topic_name | Name of the budget alerts SNS topic |
| security_alerts_subscriptions | List of security alerts email subscription ARNs |
| budget_alerts_subscriptions | List of budget alerts email subscription ARNs |

## Resources Created

- `aws_sns_topic.security_alerts`: SNS topic for security alerts
- `aws_sns_topic.budget_alerts`: SNS topic for budget alerts
- `aws_sns_topic_subscription.security_alerts_email`: Email subscriptions for security alerts
- `aws_sns_topic_subscription.budget_alerts_email`: Email subscriptions for budget alerts
- `aws_sns_topic_policy.security_alerts`: Topic policy allowing CloudTrail and EventBridge to publish
- `aws_sns_topic_policy.budget_alerts`: Topic policy allowing AWS Budgets to publish

## Important Notes

### Email Confirmation Required

After deployment, email subscriptions will be in a "PendingConfirmation" state. Recipients must:
1. Check their email inbox (and spam folder)
2. Click the confirmation link in the email from AWS
3. Confirm the subscription

**Notifications will not be sent until subscriptions are confirmed.**

### Free Tier Limits

- SNS Free Tier: 1,000 email notifications per month
- Estimated usage: ~70 emails/month (security + budget alerts)
- Well within free tier limits

### Topic Policies

The module configures topic policies to allow:
- **Security Alerts Topic**: CloudTrail and EventBridge services
- **Budget Alerts Topic**: AWS Budgets service

These policies include account ID conditions to prevent cross-account access.

## Validation

Requirements validated by this module:
- **8.1**: Creates SNS topic for security alerts
- **8.2**: Creates SNS topic for budget alerts
- **8.3**: Uses email protocol for notifications
- **8.6**: Links budget notifications to SNS topic
- **8.7**: Stays within SNS free tier limits (1000 notifications/month)
- **4.5**: Creates SNS topic for budget notifications

## Example: Multiple Email Addresses

```hcl
module "sns_notifications" {
  source = "./modules/sns-notifications"
  
  account_id = "123456789012"
  
  security_alert_emails = [
    "security-team@example.com",
    "admin@example.com"
  ]
  
  budget_alert_emails = [
    "billing@example.com",
    "finance@example.com",
    "admin@example.com"
  ]
  
  tags = {
    ManagedBy   = "Terraform"
    Project     = "AWS-Security-Setup"
    Environment = "Production"
    Owner       = "security-team@example.com"
  }
}
```

## Troubleshooting

### Emails Not Received

1. Check spam/junk folder
2. Verify email address is correct in configuration
3. Check SNS subscription status in AWS Console
4. Ensure subscription is confirmed (not "PendingConfirmation")

### Topic Policy Errors

If CloudTrail or Budgets cannot publish to topics:
1. Verify account ID is correct
2. Check topic policy includes correct service principal
3. Ensure topic policy has been applied (check AWS Console)

### Terraform Errors

If you see "AlreadyExists" errors:
- Topic names must be unique within an AWS account
- If topics already exist, import them: `terraform import aws_sns_topic.security_alerts arn:aws:sns:...`
