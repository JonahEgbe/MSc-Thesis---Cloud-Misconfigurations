# IAM-BENIGN-002: No AdministratorAccess; attach ReadOnlyAccess instead

resource "aws_iam_user" "user" {
  name = lower(format("%s-%s", var.scenario_id, local.name_suffix))
  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
