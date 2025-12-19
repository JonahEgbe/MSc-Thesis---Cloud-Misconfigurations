# IAM-MISC-001: No MFA-enforcement guardrail policy

resource "aws_iam_user" "user" {
  name = lower(format("%s-%s", var.scenario_id, local.name_suffix))
  tags = local.common_tags
}
