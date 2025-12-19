# NET-BENIGN-002: VPC flow logs enabled to CloudWatch

resource "aws_vpc" "vpc" {
  cidr_block           = "10.53.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.common_tags
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  name              = lower(format("/vpc/flowlogs/%s-%s", var.scenario_id, local.name_suffix))
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_iam_role" "flowlogs_role" {
  name = lower(format("%s-flowlogs-role-%s", var.scenario_id, local.name_suffix))

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flowlogs_policy" {
  name = lower(format("%s-flowlogs-policy-%s", var.scenario_id, local.name_suffix))
  role = aws_iam_role.flowlogs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow" {
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flowlogs.arn
  iam_role_arn         = aws_iam_role.flowlogs_role.arn

  tags = local.common_tags
}
