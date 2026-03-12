# IAM Identity Center Module
# This module configures IAM Identity Center (AWS SSO) with permission sets

# Data source to get the IAM Identity Center instance
data "aws_ssoadmin_instances" "main" {}

# Local values for easier reference
locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}
