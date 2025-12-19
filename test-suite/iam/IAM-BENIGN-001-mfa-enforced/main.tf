# IAM-BENIGN-001: Enforce MFA using a deny-unless-MFA policy

resource "aws_iam_user" "user" {
  name = lower(format("%s-%s", var.scenario_id, local.name_suffix))
  tags = local.common_tags
}

resource "aws_iam_policy" "deny_without_mfa" {
  name = lower(format("%s-mfa-%s", var.scenario_id, local.name_suffix))

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllUnlessMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = { "aws:MultiFactorAuthPresent" = "false" }
        }
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.deny_without_mfa.arn
}
