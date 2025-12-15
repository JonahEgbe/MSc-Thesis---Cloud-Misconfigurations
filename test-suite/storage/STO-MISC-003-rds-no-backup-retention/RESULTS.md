## Expected outcome
FAIL (backup_retention_period = 0)

## Primary check (what this scenario tests)
Automated backups disabled / retention = 0.

## Observed
- Checkov: CKV_AWS_133 FAILED (detected)
- tfsec: aws-rds-specify-backup-retention flagged (detected)
- Terrascan: automated backups enabled policy violated (detected)
- Conftest: passed (OPA policy currently only covers S3)
## Notes
Other findings are recorded but out-of-scope for this scenario.
