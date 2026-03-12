# Output values for budgets module

output "cost_budget_name" {
  description = "Name of the cost budget"
  value       = aws_budgets_budget.zero_dollar.name
}

output "free_tier_budget_name" {
  description = "Name of the free tier usage budget"
  value       = aws_budgets_budget.free_tier_monitor.name
}
