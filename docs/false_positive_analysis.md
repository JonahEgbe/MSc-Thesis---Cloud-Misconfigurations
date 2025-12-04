# False Positive / Precision Analysis – Storage Domain (S3)

This document summarises how each tool behaves on the Storage (S3) scenarios
with respect to **false positives** and overall **precision**.

## Current Scenarios

- **STO-MISC-001-s3-public-unencrypted** – should be detected (true positive).
- **STO-BENIGN-001-s3-private-encrypted** – ideally no HIGH findings (tests false positives).

## Initial Summary (manual from results/summary.csv)

| Tool       | Scenarios Scanned | False Positives (BENIGN flagged) | FP Rate | Notes |
|-----------|-------------------|-----------------------------------|--------|-------|
| Checkov   | 2                 | 1                                 | 50%    | Flags several best-practice gaps on BENIGN bucket. |
| tfsec     | 2                 | 1                                 | 50%    | High severity for KMS and logging on BENIGN bucket. |
| Terrascan | 2                 | 0                                 | 0%     | No violations on BENIGN, catches key MISC issues.   |
| Conftest  | 2                 | 0                                 | 0%     | Only enforces explicit public-ACL policy.           |

> These numbers will be refined once the full 50 MISC + 50 BENIGN suite is implemented.
