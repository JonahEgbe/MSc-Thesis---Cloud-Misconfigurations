# LOG-BENIGN-002: CloudWatch Log Group retention set

resource "aws_cloudwatch_log_group" "lg" {
  name              = lower(format("/app/%s-%s", var.scenario_id, local.name_suffix))
  retention_in_days = 30
  tags              = local.common_tags
}
