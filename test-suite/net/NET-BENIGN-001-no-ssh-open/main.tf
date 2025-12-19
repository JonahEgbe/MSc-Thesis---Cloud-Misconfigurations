# NET-BENIGN-001: No SSH open to world (restrict to private CIDR)

resource "aws_vpc" "vpc" {
  cidr_block           = "10.51.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.common_tags
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.51.1.0/24"
  availability_zone = "eu-west-2a"
  tags              = local.common_tags
}

resource "aws_security_group" "sg" {
  name   = lower(format("%s-sg-%s", var.scenario_id, local.name_suffix))
  vpc_id = aws_vpc.vpc.id
  tags   = local.common_tags

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.51.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
