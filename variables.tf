# Root Module Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "aws-security-setup"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "At least one email address must be provided for budget alerts."
  }
}

variable "security_alert_emails" {
  description = "Email addresses for security alerts"
  type        = list(string)

  validation {
    condition     = length(var.security_alert_emails) > 0
    error_message = "At least one email address must be provided for security alerts."
  }
}

variable "cloudtrail_log_retention_days" {
  description = "Days to retain CloudTrail logs in S3"
  type        = number
  default     = 90

  validation {
    condition     = var.cloudtrail_log_retention_days >= 30 && var.cloudtrail_log_retention_days <= 365
    error_message = "CloudTrail log retention must be between 30 and 365 days."
  }
}

variable "enable_mfa_enforcement" {
  description = "Enforce MFA for IAM Identity Center users"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "AWS-Security-Setup"
    Environment = "Production"
  }
}
