# NET-MISC-002: VPC flow logs disabled (no aws_flow_log)

resource "aws_vpc" "vpc" {
  cidr_block           = "10.52.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.common_tags
}
