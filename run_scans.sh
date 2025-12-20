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
# IMPORTANT: Use terraform.tfvars so CI/local behave the same
if [ -f "terraform.tfvars" ]; then
  terraform plan -refresh=false -var-file="terraform.tfvars" -out=tfplan.binary
else
  terraform plan -refresh=false -out=tfplan.binary
fi

echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

# We want scans to continue even if one scanner fails
set +e

echo "===== [5] Checkov ====="
if command -v checkov >/dev/null 2>&1; then
  checkov -d . --skip-download | tee "checkov_${SCENARIO_NAME}.txt"
else
  echo "checkov not installed" | tee "checkov_${SCENARIO_NAME}.txt"
fi

echo "===== [6] tfsec ====="
if command -v tfsec >/dev/null 2>&1; then
  if [ -f "terraform.tfvars" ]; then
    tfsec . --tfvars-file terraform.tfvars | tee "tfsec_${SCENARIO_NAME}.txt"
  else
    tfsec . | tee "tfsec_${SCENARIO_NAME}.txt"
  fi
else
  echo "tfsec not installed" | tee "tfsec_${SCENARIO_NAME}.txt"
fi

echo "===== [7] Terrascan ====="
if command -v terrascan >/dev/null 2>&1; then
  terrascan scan -d . --iac-type terraform | tee "terrascan_${SCENARIO_NAME}.txt"
else
  echo "terrascan not installed" | tee "terrascan_${SCENARIO_NAME}.txt"
fi

echo "===== [8] Conftest ====="
if command -v conftest >/dev/null 2>&1; then
  conftest test tfplan.json --policy ../../../policy/terraform | tee "conftest_${SCENARIO_NAME}.txt"
else
  echo "conftest not installed" | tee "conftest_${SCENARIO_NAME}.txt"
fi

exit 0
