
## Expected outcome
PASS (backup_retention_period = 7)

## Primary check (what this scenario tests)
Automated backups enabled / retention > 0.

## Observed
- Checkov: CKV_AWS_133 PASSED (meets scenario goal)
- tfsec/Terrascan: reported additional hardening findings (out-of-scope)
- Conftest: passed (no RDS rules)
