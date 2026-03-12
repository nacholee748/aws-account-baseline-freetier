# Bootstrap Module - Terraform Remote State Backend

This module creates the foundational infrastructure required for Terraform remote state management:
- **S3 Bucket**: Stores Terraform state files with versioning and encryption
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.6.0 installed
- AWS account ID

## Deployment Instructions

### Step 1: Set Your Account ID

Create a `terraform.tfvars` file:

```hcl
account_id = "123456789012"  # Replace with your AWS account ID
aws_region = "us-east-1"
```

### Step 2: Initialize and Deploy

```bash
cd bootstrap/
terraform init
terraform plan
terraform apply
```

### Step 3: Note the Outputs

After successful deployment, note the outputs:
- `terraform_state_bucket_name`: Use this in your backend configuration
- `dynamodb_table_name`: Use this for state locking

### Step 4: Migrate to Remote Backend

After the bootstrap resources are created, you can configure the main Terraform configuration to use the remote backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "<account-id>-terraform-state-us-east-1"
    key            = "aws-account-security/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Then run `terraform init -migrate-state` to move the local state to S3.

## Resources Created

### S3 Bucket
- **Name**: `<account-id>-terraform-state-<region>`
- **Versioning**: Enabled (for state recovery)
- **Encryption**: AES-256 (SSE-S3)
- **Public Access**: Blocked (all 4 settings)

### DynamoDB Table
- **Name**: `terraform-state-lock`
- **Billing Mode**: PAY_PER_REQUEST (within Free Tier)
- **Partition Key**: `LockID` (String)

## Security Features

- ✅ S3 bucket versioning for state recovery
- ✅ Server-side encryption with AES-256
- ✅ All public access blocked
- ✅ State locking to prevent concurrent modifications
- ✅ On-demand billing to stay within Free Tier

## Cost Considerations

This infrastructure is designed to stay within AWS Free Tier:
- **S3**: 5GB storage (state files are typically < 1MB)
- **DynamoDB**: 25 WCU/RCU (state operations use < 1 per deployment)

## Troubleshooting

### Bucket Name Already Exists
If you get an error that the bucket name already exists, it means:
1. The bucket was created previously in your account
2. The bucket exists in another AWS account (bucket names are globally unique)

Solution: Either use the existing bucket or choose a different naming pattern.

### Insufficient Permissions
Ensure your AWS credentials have permissions to:
- Create S3 buckets
- Create DynamoDB tables
- Configure S3 bucket policies and encryption

## Next Steps

After deploying the bootstrap module:
1. Configure the main Terraform project to use the remote backend
2. Run `terraform init -migrate-state` in the main project
3. Verify the state file appears in the S3 bucket
4. Deploy the remaining security infrastructure modules
