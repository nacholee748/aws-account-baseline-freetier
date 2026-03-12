# Outputs for SNS Notifications Module

output "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "security_alerts_topic_name" {
  description = "Name of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.name
}

output "budget_alerts_topic_arn" {
  description = "ARN of the budget alerts SNS topic"
  value       = aws_sns_topic.budget_alerts.arn
}

output "budget_alerts_topic_name" {
  description = "Name of the budget alerts SNS topic"
  value       = aws_sns_topic.budget_alerts.name
}

output "security_alerts_subscriptions" {
  description = "List of security alerts email subscription ARNs"
  value       = aws_sns_topic_subscription.security_alerts_email[*].arn
}

output "budget_alerts_subscriptions" {
  description = "List of budget alerts email subscription ARNs"
  value       = aws_sns_topic_subscription.budget_alerts_email[*].arn
}
