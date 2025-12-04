# Cloud Misconfiguration Test Suite Plan (100 Scenarios)

Each domain will have 10 MISC + 10 BENIGN scenarios (20 per domain, 100 total).

## 1. Storage (STO)

- S3 (STO-MISC-001 / STO-BENIGN-001) – CIS S3.8, S3.9, S3.17
- Additional S3 variants: public via policy, missing SSE, logging disabled, etc.
- RDS snapshots public, EBS snapshots public, etc. (STO-0xx).

## 2. IAM (IAM)

- Over-privileged policies, wildcard actions/resources.
- Orphaned users, access keys not rotated, etc.

## 3. Network (NET)

- Public security groups, open SSH/RDP, missing NACLs, no VPC flow logs.

## 4. Compute (CMP)

- EC2 with public AMIs, instance profiles too permissive, unencrypted EBS.

## 5. Management / Logging (LOG)

- CloudTrail disabled/partial, Config not recording, GuardDuty off, etc.

Each scenario will be tagged with:
- Domain (STO / IAM / NET / CMP / LOG)
- Type (MISC / BENIGN)
- Primary CIS v5.0.0 control(s).
