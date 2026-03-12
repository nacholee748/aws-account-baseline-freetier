# Variables for SNS Notifications Module

variable "security_alert_emails" {
  description = "List of email addresses to receive security alerts"
  type        = list(string)

  validation {
    condition     = length(var.security_alert_emails) > 0
    error_message = "At least one email address must be provided for security alerts."
  }
}

variable "budget_alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "At least one email address must be provided for budget alerts."
  }
}

variable "account_id" {
  description = "AWS account ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "aws_region" {
  description = "AWS region for SNS topics"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
