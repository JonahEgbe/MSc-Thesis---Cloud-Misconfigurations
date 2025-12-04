# Scenario: STO-BENIGN-001
# Title: Private, encrypted S3 bucket with no public access
# ============================================================================
# Scenario Metadata
# ============================================================================
# ID: STO-BENIGN-001
# Title: Private S3 bucket with encryption and public access blocked
# Domain: Storage
# Type: BENIGN
#CIS Standards: CIS AWS Foundation Benchmark v5.0.0
# CIS Controls:
#   - CIS AWS S3.1 – no public access via ACL or policy
#   - CIS AWS S3.17 – default encryption at rest enabled
#   - CIS AWS S3.22 – (data-event logging) may or may not be enforced depending on CloudTrail Configuration.
# Severity: LOW (baseline-compliant)
# Expected Detection:
#   - Checkov: PASS all checks related to public access; MAY FAIL on
#              optional hardening checks (logging, lifecycle, KMS key)
#   - tfsec: MAY report non-critical findings (e.g., not using CMK,
#            logging not enabled) but should not flag public exposure
#   - Terrascan: PASS (no violated policies for public ACL or
#                missing baseline controls)
#   - Conftest: PASS (no disallowed public ACLs in the tfplan)
# Description:
#   Secure S3 bucket with public access block enabled, versioning and
#   default encryption configured, representing a CIS-compliant storage
#   baseline. Used to measure false positive behaviour of tools.
# Expected Result:
#   - TRUE_NEGATIVE for Conftest and Terrascan (no violations)
#   - Potential NON-CRITICAL findings from Checkov/tfsec for extra
#     hardening (logging, lifecycle, CMK) – documented as acceptable.
# ============================================================================

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
