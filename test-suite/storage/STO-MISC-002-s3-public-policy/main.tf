# STO-MISC-002: Public S3 via Bucket Policy (Principal "*")

resource "aws_s3_bucket" "bucket" {
  bucket        = lower(format("%s-%s", substr(var.scenario_id, 0, 40), local.name_suffix))
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}
