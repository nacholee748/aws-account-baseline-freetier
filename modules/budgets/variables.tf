# Input variables for budgets module

variable "budget_sns_topic_arn" {
  description = "ARN of the SNS topic for budget notifications"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
