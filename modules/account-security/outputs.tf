# Outputs for account-security module

output "password_policy_expire_passwords" {
  description = "Indicates whether passwords expire (max_password_age is set)"
  value       = aws_iam_account_password_policy.strict.expire_passwords
}

output "password_policy_minimum_length" {
  description = "Minimum password length configured"
  value       = aws_iam_account_password_policy.strict.minimum_password_length
}

output "s3_public_access_block_id" {
  description = "ID of the S3 account public access block configuration"
  value       = aws_s3_account_public_access_block.account_level.id
}

output "s3_block_public_acls" {
  description = "Whether Amazon S3 blocks public ACLs for buckets in this account"
  value       = aws_s3_account_public_access_block.account_level.block_public_acls
}

output "s3_block_public_policy" {
  description = "Whether Amazon S3 blocks public bucket policies for buckets in this account"
  value       = aws_s3_account_public_access_block.account_level.block_public_policy
}

output "s3_ignore_public_acls" {
  description = "Whether Amazon S3 ignores public ACLs for buckets in this account"
  value       = aws_s3_account_public_access_block.account_level.ignore_public_acls
}

output "s3_restrict_public_buckets" {
  description = "Whether Amazon S3 restricts public bucket policies for buckets in this account"
  value       = aws_s3_account_public_access_block.account_level.restrict_public_buckets
}
