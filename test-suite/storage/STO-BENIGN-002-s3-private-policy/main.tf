# STO-BENIGN-002: Private S3 with strict account-only policy + encryption

data "aws_caller_identity" "current" {}

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

resource "aws_s3_bucket_policy" "account_only" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccountOnlyAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "s3:*"
        Resource = [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]
      }
    ]
  })
}
