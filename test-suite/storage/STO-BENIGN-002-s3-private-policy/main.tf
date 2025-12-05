# ============================================================================
# Scenario Metadata
# ============================================================================
# ID: STO-BENIGN-002
# Title: Private S3 bucket with strict bucket policy and encryption
# Domain: Storage (STO)
# Type: BENIGN
# CIS Controls (v5.0.0):
#   - CIS AWS S3.9  – Ensure S3 bucket object-level logging is enabled (OPTIONAL here)
#   - CIS AWS S3.17 – Ensure S3 bucket default encryption is enabled
# Severity: LOW (baseline-compliant)
# Expected Detection:
#   - Checkov: PASS on public-access checks; MAY raise non-critical findings
#             (e.g. CMK vs SSE-S3, logging not enabled).
#   - tfsec: MAY raise informational findings but should not flag public exposure.
#   - Terrascan: TRUE_NEGATIVE (no public bucket / snapshot policies).
#   - Conftest: TRUE_NEGATIVE (no disallowed public ACL or bucket policy).
# Description:
#   Secure S3 bucket using a strict bucket policy that only allows access for
#   the current AWS account (root or a specific IAM principal). Default
#   encryption is enabled, and no public principals are granted access.
#   Used as a benign counterpart to STO-MISC-002 to measure false positives.
# Expected Result:
#   - TRUE_NEGATIVE for Conftest and Terrascan.
#   - No HIGH/CRITICAL findings from Checkov/tfsec related to public exposure.
# ============================================================================

# S3 bucket (private, tagged, baseline-hardened)
resource "aws_s3_bucket" "private_policy_bucket" {
  bucket = "jonah-private-policy-bucket-01"

  tags = {
    scenario_id  = "STO-BENIGN-002-s3-private-policy"
    domain       = "STO"
    type         = "BENIGN"
    cis_controls = "S3.9,S3.17"
  }
}

# Block all forms of public access (bucket-level guardrail)
resource "aws_s3_bucket_public_access_block" "private_block" {
  bucket = aws_s3_bucket.private_policy_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default encryption at rest (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "private_encrypt" {
  bucket = aws_s3_bucket.private_policy_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning enabled (for recovery)
resource "aws_s3_bucket_versioning" "private_versioning" {
  bucket = aws_s3_bucket.private_policy_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Strict bucket policy – account-only access
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "private_policy" {
  bucket = aws_s3_bucket.private_policy_bucket.id

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
        Resource = [
          aws_s3_bucket.private_policy_bucket.arn,
          "${aws_s3_bucket.private_policy_bucket.arn}/*"
        ]
      }
    ]
  })
}
