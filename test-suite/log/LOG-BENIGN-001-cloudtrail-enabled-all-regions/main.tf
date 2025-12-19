# LOG-BENIGN-001: CloudTrail enabled, multi-region, global events

resource "aws_s3_bucket" "trail_bucket" {
  bucket        = lower(format("%s-%s", substr(var.scenario_id, 0, 40), local.name_suffix))
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_cloudtrail" "trail" {
  name                          = lower(format("%s-%s", var.scenario_id, local.name_suffix))
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true

  tags = local.common_tags
}
