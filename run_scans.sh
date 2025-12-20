#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <scenario-dir>" >&2
  exit 1
fi

SCENARIO_DIR="$1"
SCENARIO_NAME="$(basename "$SCENARIO_DIR")"

echo "==> Scenario directory: $SCENARIO_DIR"

cd "$SCENARIO_DIR"

echo "===== [1] Terraform init ====="
terraform init -input=false -upgrade

echo "===== [2] Terraform validate ====="
terraform validate

echo "===== [3] Terraform plan ====="
# IMPORTANT: load terraform.tfvars so profile/metadata variables are applied
terraform plan -refresh=false -var-file="terraform.tfvars" -out=tfplan.binary

echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

set +e

echo "===== [5] Checkov ====="
checkov -d . --skip-download | tee "checkov_${SCENARIO_NAME}.txt"
CHECKOV_RC=${PIPESTATUS[0]}

echo "===== [6] tfsec ====="
tfsec . --tfvars-file "terraform.tfvars" | tee "tfsec_${SCENARIO_NAME}.txt"
TFSEC_RC=${PIPESTATUS[0]}

echo "===== [7] Terrascan ====="
terrascan scan -d . --iac-type terraform | tee "terrascan_${SCENARIO_NAME}.txt"
TERRASCAN_RC=${PIPESTATUS[0]}

echo "===== [8] Conftest ====="
conftest test tfplan.json --policy ../../../policy/terraform | tee "conftest_${SCENARIO_NAME}.txt"
CONFTEST_RC=${PIPESTATUS[0]}

# If you want strict gating later, we can enforce rules here.
# For now, keep outputs + exit non-zero only if Terraform failed earlier (it didn't).
exit 0
