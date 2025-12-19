# IAM-MISC-002: AdministratorAccess attached to a user

resource "aws_iam_user" "user" {
  name = lower(format("%s-%s", var.scenario_id, local.name_suffix))
  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
