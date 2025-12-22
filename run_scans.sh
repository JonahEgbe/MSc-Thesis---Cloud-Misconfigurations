#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <scenario-dir>" >&2
  exit 1
fi

SCENARIO_DIR="$1"
SCENARIO_DIR="$(cd "$SCENARIO_DIR" && pwd)"
SCENARIO_NAME="$(basename "$SCENARIO_DIR")"

echo "==> Scenario directory: $SCENARIO_DIR"

# Work inside scenario dir (so tools output land here)
cd "$SCENARIO_DIR"

# Create a dedicated log folder inside the scenario
LOG_DIR="${SCENARIO_DIR}/scan_logs"
mkdir -p "$LOG_DIR"

TS="$(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
MASTER_LOG="${LOG_DIR}/FULL_${SCENARIO_NAME}.log"

# Print AND capture everything (full scrollback becomes the master log)
exec > >(tee -a "$MASTER_LOG") 2>&1

echo
echo "============================================================"
echo "FULL SCAN LOG START: $TS"
echo "Scenario: $SCENARIO_NAME"
echo "Path: $SCENARIO_DIR"
echo "============================================================"
echo

echo "===== [1] Terraform init ====="

# Ensure TF plugin cache exists (prevents terraform init warning)
if [ -n "${TF_PLUGIN_CACHE_DIR:-}" ]; then
  mkdir -p "$TF_PLUGIN_CACHE_DIR" || true
fi

terraform init -input=false -upgrade

echo "===== [2] Terraform validate ====="
terraform validate

echo "===== [3] Terraform plan ====="
# IMPORTANT: load terraform.tfvars so profile/metadata variables are applied
terraform plan -refresh=false -var-file="terraform.tfvars" -out=tfplan.binary

echo
echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

# Do not stop the script if scanners fail
set +e

echo
echo "===== [5] Checkov ====="
checkov -d . --skip-download | tee "${LOG_DIR}/checkov_${SCENARIO_NAME}.txt"
CHECKOV_RC=${PIPESTATUS[0]}

echo
echo "===== [6] tfsec ====="
tfsec . --tfvars-file "terraform.tfvars" | tee "${LOG_DIR}/tfsec_${SCENARIO_NAME}.txt"
TFSEC_RC=${PIPESTATUS[0]}

echo
echo "===== [7] Terrascan ====="
# Skip non-terraform folders that live inside scenarios
terrascan scan -d . --iac-type terraform \
  --skip-dirs "github_conf,scan_logs,.terraform" | tee "${LOG_DIR}/terrascan_${SCENARIO_NAME}.txt"
TERRASCAN_RC=${PIPESTATUS[0]}

echo
echo "===== [8] Conftest ====="
# You currently only have s3.rego in policy/terraform; conftest will still run.
conftest test tfplan.json --policy ../../../policy/terraform | tee "${LOG_DIR}/conftest_${SCENARIO_NAME}.txt"
CONFTEST_RC=${PIPESTATUS[0]}

echo
echo "============================================================"
echo "FULL SCAN LOG END: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
echo "Return codes:"
echo "  checkov   = ${CHECKOV_RC}"
echo "  tfsec     = ${TFSEC_RC}"
echo "  terrascan = ${TERRASCAN_RC}"
echo "  conftest  = ${CONFTEST_RC}"
echo "Master log: ${MASTER_LOG}"
echo "============================================================"
echo

# Always exit 0 (Option A: no gating; you want outputs)
exit 0
