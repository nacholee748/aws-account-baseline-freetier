# EC2 IMDSv2 Enforcement Policy
# This IAM policy can be attached to EC2 instance roles to enforce IMDSv2

# IAM policy document that requires IMDSv2 for EC2 instances
data "aws_iam_policy_document" "require_imdsv2" {
  statement {
    sid    = "RequireIMDSv2"
    effect = "Deny"

    actions = [
      "ec2:RunInstances"
    ]

    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "ec2:MetadataHttpTokens"
      values   = ["required"]
    }
  }

  statement {
    sid    = "RequireIMDSv2HopLimit"
    effect = "Deny"

    actions = [
      "ec2:RunInstances"
    ]

    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]

    condition {
      test     = "NumericGreaterThan"
      variable = "ec2:MetadataHttpPutResponseHopLimit"
      values   = ["1"]
    }
  }
}

# Output the policy JSON for use in IAM roles
output "imdsv2_policy_json" {
  description = "IAM policy JSON that enforces IMDSv2 for EC2 instances"
  value       = data.aws_iam_policy_document.require_imdsv2.json
}
