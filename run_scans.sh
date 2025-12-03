#!/usr/bin/env bash
set -u
set -o pipefail

SCENARIO_DIR="$1"

echo "==> Scenario directory: $SCENARIO_DIR"

cd "$SCENARIO_DIR"

SCENARIO_NAME=$(basename "$SCENARIO_DIR")

echo
echo "===== [1] Terraform init ====="
terraform init -input=false

echo
echo "===== [2] Terraform validate ====="
terraform validate

echo
echo "===== [3] Terraform plan (profile = terraform_user) ====="
terraform plan -out=tfplan.binary

echo
echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

# ---------- RESULTS FILE NAMES ----------
CHECKOV_OUT="checkov_${SCENARIO_NAME}.txt"
TFSEC_OUT="tfsec_${SCENARIO_NAME}.txt"
TERRASCAN_OUT="terrascan_${SCENARIO_NAME}.txt"
CONFTEST_OUT="conftest_${SCENARIO_NAME}.txt"

echo
echo "===== [5] Checkov (Terraform files + plan) ====="
( checkov -d . --framework terraform,terraform_plan,secrets || true ) | tee "$CHECKOV_OUT"

echo
echo "===== [6] tfsec ====="
( tfsec . || true ) | tee "$TFSEC_OUT"

echo
echo "===== [7] Terrascan ====="
( terrascan scan -d . || true ) | tee "$TERRASCAN_OUT"

echo
echo "===== [8] Conftest ====="
conftest test tfplan.json --policy ../../../policy/terraform/ | tee "$CONFTEST_OUT"
