# SNS Topics and Subscriptions

# Security Alerts Topic
resource "aws_sns_topic" "security_alerts" {
  name         = "security-alerts"
  display_name = "AWS Security Alerts"

  tags = merge(
    var.tags,
    {
      Purpose   = "SecurityNotifications"
      DataClass = "SecurityEvents"
    }
  )
}

# Budget Alerts Topic
resource "aws_sns_topic" "budget_alerts" {
  name         = "budget-alerts"
  display_name = "AWS Budget Alerts"

  tags = merge(
    var.tags,
    {
      Purpose   = "BudgetNotifications"
      DataClass = "CostAlerts"
    }
  )
}

# Email Subscriptions for Security Alerts
resource "aws_sns_topic_subscription" "security_alerts_email" {
  count     = length(var.security_alert_emails)
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_emails[count.index]
}

# Email Subscriptions for Budget Alerts
resource "aws_sns_topic_subscription" "budget_alerts_email" {
  count     = length(var.budget_alert_emails)
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}

# Topic Policy for Security Alerts
# Allows CloudTrail and other AWS services to publish to the topic
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      },
      {
        Sid    = "AllowEventsPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

# Topic Policy for Budget Alerts
# Allows AWS Budgets service to publish to the topic
resource "aws_sns_topic_policy" "budget_alerts" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBudgetsPublish"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}
