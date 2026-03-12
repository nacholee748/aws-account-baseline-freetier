# Variables for Bootstrap Module

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID (used for unique bucket naming)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "AWS-Security-Setup"
    Environment = "Production"
  }

  validation {
    condition = (
      contains(keys(var.tags), "ManagedBy") &&
      contains(keys(var.tags), "Project") &&
      contains(keys(var.tags), "Environment")
    )
    error_message = "Tags must include ManagedBy, Project, and Environment."
  }
}
