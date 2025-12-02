resource "aws_s3_bucket" "public_bucket" {
  bucket = "jonah-public-bucket-test-01"
}

resource "aws_s3_bucket_ownership_controls" "public_bucket_ownership" {
  bucket = aws_s3_bucket.public_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"  # allows ACLs
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public_bucket_acl" {
  bucket     = aws_s3_bucket.public_bucket.id
  acl        = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.public_bucket_ownership
  ]
}
