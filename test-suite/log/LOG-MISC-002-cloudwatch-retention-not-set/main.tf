# LOG-MISC-002: CloudWatch Log Group retention NOT set (infinite)

resource "aws_cloudwatch_log_group" "lg" {
  name = lower(format("/app/%s-%s", var.scenario_id, local.name_suffix))
  tags = local.common_tags
}
