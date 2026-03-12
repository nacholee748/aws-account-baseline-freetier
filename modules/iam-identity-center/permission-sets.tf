# Permission Sets for IAM Identity Center

# Admin Permission Set - Full administrative access
resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdminPermissionSet"
  description      = "Full administrative access to AWS account"
  instance_arn     = local.instance_arn
  session_duration = "PT4H" # 4 hours

  tags = merge(
    var.tags,
    {
      AccessLevel = "Admin"
      MFARequired = "true"
    }
  )
}

# Attach AdministratorAccess managed policy to Admin permission set
resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Developer Permission Set - PowerUser with IAM restrictions
resource "aws_ssoadmin_permission_set" "developer" {
  name             = "DeveloperPermissionSet"
  description      = "Developer access with restrictions on IAM, budgets, and audit services"
  instance_arn     = local.instance_arn
  session_duration = "PT8H" # 8 hours

  tags = merge(
    var.tags,
    {
      AccessLevel = "Developer"
      MFARequired = "true"
    }
  )
}

# Attach PowerUserAccess managed policy to Developer permission set
resource "aws_ssoadmin_managed_policy_attachment" "developer" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Inline policy for Developer to deny IAM, Organizations, Budgets, and CloudTrail changes
resource "aws_ssoadmin_permission_set_inline_policy" "developer" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "iam:*",
          "organizations:*",
          "account:*",
          "budgets:*",
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ReadOnly Permission Set - Read-only access across all services
resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "ReadOnlyPermissionSet"
  description      = "Read-only access across all AWS services"
  instance_arn     = local.instance_arn
  session_duration = "PT12H" # 12 hours

  tags = merge(
    var.tags,
    {
      AccessLevel = "ReadOnly"
      MFARequired = "true"
    }
  )
}

# Attach ReadOnlyAccess managed policy to ReadOnly permission set
resource "aws_ssoadmin_managed_policy_attachment" "readonly" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
