#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <scenario-dir>" >&2
  exit 1
fi

SCENARIO_DIR="$1"
SCENARIO_NAME=$(basename "$SCENARIO_DIR")

echo "==> Scenario directory: $SCENARIO_DIR"

cd "$SCENARIO_DIR"

echo "===== [1] Terraform init ====="
terraform init -input=false -upgrade

echo "===== [2] Terraform validate ====="
terraform validate

echo "===== [3] Terraform plan ====="
terraform plan -refresh=false -out=tfplan.binary

echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

set +e

echo "===== [5] Checkov ====="
checkov -d . --skip-download | tee "checkov_${SCENARIO_NAME}.txt"

echo "===== [6] tfsec ====="
tfsec . | tee "tfsec_${SCENARIO_NAME}.txt"

echo "===== [7] Terrascan ====="
terrascan scan -d . --iac-type terraform | tee "terrascan_${SCENARIO_NAME}.txt"

echo "===== [8] Conftest ====="
conftest test tfplan.json --policy ../../../policy/terraform | tee "conftest_${SCENARIO_NAME}.txt"
