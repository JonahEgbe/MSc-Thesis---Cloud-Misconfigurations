# CMP-BENIGN-002: IMDSv2 required (http_tokens = required)

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.al2.id
  instance_type = "t3.micro"

  metadata_options {
    http_tokens = "required"
  }

  tags = local.common_tags
}
