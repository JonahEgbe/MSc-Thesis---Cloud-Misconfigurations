# ============================================================================
# Scenario Metadata
# ============================================================================
# ID: STO-MISC-001
# Title: Public S3 bucket with insecure ACL and missing hardening
# Domain: Storage
# Type: MISC
#CIS Standards: CIS AWS Foundation Benchmark v5.0.0
# CIS Controls:
#   - CIS AWS S3.8 – Ensure that S3 buckets are not publicly accessible
#   - CIS AWS S3.9 – Ensure S3 bucket access logging is enabled
#   - CIS AWS S3.17 – Ensure S3 bucket default encryption is enabled
# Severity: HIGH
# Expected Detection:
#   - Checkov: FAIL (CKV_AWS_20, CKV_AWS_53–56, CKV_AWS_18, CKV_AWS_21, CKV_AWS_144, CKV_AWS_145, CKV2_AWS_6, CKV2_AWS_61–62, CKV2_AWS_65)
#   - tfsec: FAIL (aws-s3-no-public-access-with-acl, aws-s3-block-public-acls,
#                  aws-s3-block-public-policy, aws-s3-ignore-public-acls,
#                  aws-s3-no-public-buckets, aws-s3-enable-bucket-encryption,
#                  aws-s3-enable-bucket-logging, aws-s3-enable-versioning)
#   - Terrascan: FAIL (public ACL + missing versioning/logging policies)
#   - Conftest: FAIL (public_read ACL policy)
# Description:
#   Misconfigured S3 bucket with 'public-read' ACL, no public access
#   blocking, and weak hardening (no logging, versioning, lifecycle
#   configuration, or KMS-by-default encryption). Represents a Capital
#   One–style public bucket exposure pattern.
# Expected Result: TRUE_POSITIVE (all tools should flag this scenario)
# ============================================================================

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
