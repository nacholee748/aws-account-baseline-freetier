# Free Tier usage monitoring budget
# Monitors overall usage across all services to stay within free tier

resource "aws_budgets_budget" "free_tier_monitor" {
  name        = "free-tier-usage-monitor"
  budget_type = "USAGE"
  time_unit   = "MONTHLY"

  # Monitor S3 storage usage in GB
  limit_amount = "5"
  limit_unit   = "GB"

  # Filter by UsageType for S3 storage
  cost_filter {
    name = "UsageType"
    values = [
      "TimedStorage-ByteHrs"
    ]
  }

  # Alert at 80% of free tier limits (4GB)
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80.0
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [var.budget_sns_topic_arn]
  }

  tags = var.tags
}
