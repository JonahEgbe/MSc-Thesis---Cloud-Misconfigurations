/*
# ============================================================================
# Scenario Metadata
# ============================================================================
# ID: STO-MISC-002
# Title: Public S3 bucket via bucket policy (Principal "*")
# Domain: Storage (STO)
# Type: MISC
# CIS Controls (v5.0.0):
#   - CIS AWS S3.8  – Ensure S3 buckets are not publicly accessible
#   - CIS AWS S3.17 – Ensure S3 bucket default encryption is enabled
# Severity: HIGH
# Expected Detection:
#   - Checkov: TRUE_POSITIVE (public access via bucket policy, missing hardening)
#   - tfsec: TRUE_POSITIVE (public bucket / weak encryption posture)
#   - Terrascan: TRUE_POSITIVE (public S3 exposure)
#   - Conftest: 
#       * CURRENTLY: may MISS policy-based public access (policy only checks ACL).
#       * FUTURE: once Rego is extended to inspect bucket policies, should be TRUE_POSITIVE.
# Description:
#   S3 bucket where the ACL is left at default/private but the bucket policy
#   explicitly grants s3:GetObject to Principal "*" for all objects. This
#   models a common real-world misconfiguration where policy, not ACL, causes
#   data exposure.
# Expected Result:
#   - At least Checkov/tfsec/Terrascan flag the risk as HIGH.
#   - Conftest initially may be a FALSE_NEGATIVE until policy rules are added.
# ============================================================================
Scenario_ID  = "STO-MISC-002-s3-public-policy"
Domain       = "STO"          # Storage
Type         = "MISC"
CIS_Controls = ["S3.1", "S3.8"]
Description  = "S3 bucket with private ACL but bucket policy grants public read access."
*/

resource "aws_s3_bucket" "public_policy_bucket" {
  bucket = "jonah-public-policy-bucket-01"

  tags = {
    scenario_id  = "STO-MISC-002-s3-public-policy"
    domain       = "STO"
    type         = "MISC"
    cis_controls = "S3.1,S3.8"
  }
}

# Bucket policy that allows public READ via Principal "*"
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.public_policy_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_policy_bucket.arn}/*"
      }
    ]
  })
}
