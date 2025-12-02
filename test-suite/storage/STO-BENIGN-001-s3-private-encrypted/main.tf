# Scenario: STO-BENIGN-001
# Title: Private, encrypted S3 bucket with no public access

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "Jonah-secure-bucket-test-01"
}

resource "aws_s3_bucket_public_access_block" "security" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
