# STO-BENIGN-003: RDS backup retention set (>= 7)

resource "random_password" "db" {
  length  = 16
  special = true
}

resource "aws_db_instance" "rds" {
  identifier        = lower(format("%s-%s", substr(var.scenario_id, 0, 40), local.name_suffix))
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "adminuser"
  password = random_password.db.result

  backup_retention_period = 7
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = local.common_tags
}
