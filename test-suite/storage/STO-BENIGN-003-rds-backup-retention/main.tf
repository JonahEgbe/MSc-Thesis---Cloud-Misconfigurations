resource "aws_db_instance" "rds_backup_ok" {
  identifier              = "sto-benign-003-rds-backup"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  username = "adminuser"
  password = "Admin123456!"

  backup_retention_period = 7   # SECURE
  skip_final_snapshot     = true

  publicly_accessible = false

  tags = {
    scenario_id = "STO-BENIGN-003-rds-backup-retention"
    domain      = "STO"
    type        = "BENIGN"
  }
}
