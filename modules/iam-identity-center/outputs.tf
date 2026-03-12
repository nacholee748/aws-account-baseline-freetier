# Outputs for IAM Identity Center module

output "admin_permission_set_arn" {
  description = "ARN of the Admin permission set"
  value       = aws_ssoadmin_permission_set.admin.arn
}

output "developer_permission_set_arn" {
  description = "ARN of the Developer permission set"
  value       = aws_ssoadmin_permission_set.developer.arn
}

output "readonly_permission_set_arn" {
  description = "ARN of the ReadOnly permission set"
  value       = aws_ssoadmin_permission_set.readonly.arn
}

output "instance_arn" {
  description = "ARN of the IAM Identity Center instance"
  value       = local.instance_arn
}

output "identity_store_id" {
  description = "ID of the Identity Store"
  value       = local.identity_store_id
}
