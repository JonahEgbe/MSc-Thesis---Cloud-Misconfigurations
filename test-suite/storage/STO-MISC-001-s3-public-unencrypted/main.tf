# ============================================================================
# ID: STO-MISC-001
# Title: Public S3 bucket via ACL (public-read) with no public access blocking
# Domain: STO (Storage)
# Type: MISC
# CIS: S3.8 (Not Public), S3.17 (Encryption), S3.9 (Logging) - intentionally violated
# Expected: Checkov/tfsec/Terrascan FAIL; Conftest FAIL (ACL public-read)
# ============================================================================

# NOTE:
# - Bucket name MUST be globally unique + lowercase.
# - Your locals.tf provides random suffix: local.name_suffix
# - Your provider.tf sets default tags automatically.

resource "aws_s3_bucket" "public_bucket" {
  bucket        = lower(format("%s-%s", substr(replace(var.scenario_id, "_", "-"), 0, 40), local.name_suffix))
  force_destroy = true

  tags = local.common_tags
}

# Allow ACLs (required when using aws_s3_bucket_acl)
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.public_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Explicitly do NOT block public access (misconfiguration)
resource "aws_s3_bucket_public_access_block" "no_block" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public-read ACL (misconfiguration)
resource "aws_s3_bucket_acl" "public_read" {
  bucket = aws_s3_bucket.public_bucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.ownership
  ]
}
