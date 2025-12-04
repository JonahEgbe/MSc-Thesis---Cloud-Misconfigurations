# CIS Benchmark Mapping for Storage Domain (v5.0.0)

This document maps each Storage test scenario to the latest
**CIS AWS Foundations Benchmark v5.0.0** controls.

---

## Storage Domain (S3 Scenarios)

| Scenario ID                           | Type    | Description                                   | CIS Controls (v5.0.0) |
|---------------------------------------|---------|-----------------------------------------------|-------------------------|
| STO-MISC-001-s3-public-unencrypted    | MISC    | Public bucket, no encryption, no logging      | S3.8, S3.9, S3.17       |
| STO-BENIGN-001-s3-private-encrypted   | BENIGN  | Private bucket, SSE enabled, no public access | S3.9, S3.17             |

---

### 🔍 CIS v5.0.0 Control Reference

- **CIS AWS S3.8** – Ensure S3 buckets are not publicly accessible  
- **CIS AWS S3.9** – Ensure S3 bucket object-level logging (CloudTrail data events) is enabled  
- **CIS AWS S3.17** – Ensure S3 bucket default encryption is enabled  

These mappings will be expanded as new STO scenarios are added (STO-002 → STO-010).
