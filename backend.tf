# Terraform Backend Configuration
# 
# This backend configuration uses the S3 bucket and DynamoDB table
# created by the bootstrap module for remote state storage and locking.
#
# IMPORTANT: Before using this backend configuration:
# 1. Run the bootstrap module first to create the S3 bucket and DynamoDB table
# 2. Update the bucket name below with your actual account ID
# 3. Run `terraform init` to migrate state to the remote backend
#
# Example bucket name format: 123456789012-terraform-state-us-east-1

terraform {
  backend "s3" {
    # S3 bucket created by bootstrap module
    bucket = "114594328821-terraform-state-us-east-1"

    # State file path within the bucket
    key = "aws-account-security/terraform.tfstate"

    # AWS region where the S3 bucket is located
    region = "us-east-1"

    # AWS profile to use
    profile = "nacholee"

    # Enable encryption at rest for the state file
    encrypt = true

    # DynamoDB table for state locking to prevent concurrent modifications
    dynamodb_table = "terraform-state-lock"
  }
}
