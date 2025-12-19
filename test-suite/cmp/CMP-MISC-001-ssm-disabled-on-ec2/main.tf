# CMP-MISC-001: EC2 without SSM instance profile

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.common_tags
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.60.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = false
  tags              = local.common_tags
}

resource "aws_security_group" "sg" {
  name   = lower(format("%s-sg-%s", var.scenario_id, local.name_suffix))
  vpc_id = aws_vpc.vpc.id
  tags   = local.common_tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = false

  # Intentionally NO iam_instance_profile (SSM disabled)
  tags = local.common_tags
}
