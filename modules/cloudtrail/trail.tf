# CloudTrail trail for account audit
resource "aws_cloudtrail" "main" {
  name                          = "account-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # No data events to stay within free tier
    data_resource {
      type   = "AWS::S3::Object"
      values = []
    }
  }

  tags = merge(
    var.tags,
    {
      Purpose = "Audit"
    }
  )

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}
