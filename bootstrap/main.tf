# Bootstrap Module - Terraform Remote State Backend
# This module creates the S3 bucket and DynamoDB table required for Terraform remote state
# Deploy this first with local backend, then migrate state to remote backend

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "nacholee"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.account_id}-terraform-state-${var.aws_region}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_id}-terraform-state-${var.aws_region}"
      Purpose     = "TerraformState"
      DataClass   = "Infrastructure"
      Description = "Terraform remote state storage"
    }
  )
}

# Enable Versioning for State Bucket (critical for state recovery)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption with AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block All Public Access to State Bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = "terraform-state-lock"
      Purpose     = "TerraformStateLocking"
      Description = "DynamoDB table for Terraform state locking"
    }
  )
}
