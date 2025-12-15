resource "aws_db_instance" "rds_no_backup" {
  identifier              = "sto-misc-003-rds-no-backup"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  username = "adminuser"
  password = "Admin123456!"

  backup_retention_period = 0   # MISCONFIG
  skip_final_snapshot     = true

  publicly_accessible = false

  tags = {
    scenario_id = "STO-MISC-003-rds-no-backup-retention"
    domain      = "STO"
    type        = "MISC"
  }
}
