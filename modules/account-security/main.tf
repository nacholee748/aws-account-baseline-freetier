# Account-level security policies module
# This module applies security configurations at the AWS account level

# S3 Account Public Access Block
# Blocks all public access to S3 buckets at the account level
resource "aws_s3_account_public_access_block" "account_level" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Account Password Policy
# Enforces strong password requirements for IAM users
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
}
