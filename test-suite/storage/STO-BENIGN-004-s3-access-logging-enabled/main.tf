# STO-BENIGN-004: S3 access logging enabled (target bucket + source bucket)

resource "aws_s3_bucket" "log_bucket" {
  bucket        = lower(format("%s-logs-%s", substr(var.scenario_id, 0, 30), local.name_suffix))
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "log_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "bucket" {
  bucket        = lower(format("%s-%s", substr(var.scenario_id, 0, 40), local.name_suffix))
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}
