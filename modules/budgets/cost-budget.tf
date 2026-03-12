# Low-cost budget with alerts at $1 and $5 USD
# Note: AWS requires budget limit to be at least $0.01

resource "aws_budgets_budget" "zero_dollar" {
  name              = "low-cost-budget"
  budget_type       = "COST"
  limit_amount      = "0.01"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  # Forecasted alert at $5 USD
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 5.0
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [var.budget_sns_topic_arn]
  }

  # Actual alert at $1 USD
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 1.0
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [var.budget_sns_topic_arn]
  }

  # Actual alert at $5 USD
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 5.0
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [var.budget_sns_topic_arn]
  }

  tags = var.tags
}
