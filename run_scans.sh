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

cd "$SCENARIO_DIR"

LOG_DIR="${SCENARIO_DIR}/scan_logs"
mkdir -p "$LOG_DIR"

TS="$(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
MASTER_LOG="${LOG_DIR}/FULL_${SCENARIO_NAME}.log"

# Capture EVERYTHING (terminal + master log)
exec > >(tee -a "$MASTER_LOG") 2>&1

echo
echo "============================================================"
echo "FULL SCAN LOG START: $TS"
echo "Scenario: $SCENARIO_NAME"
echo "Path: $SCENARIO_DIR"
echo "============================================================"
echo

echo "===== [1] Terraform init ====="

# Ensure Terraform plugin cache exists to avoid warnings (Codespaces/CI)
if [ -z "${TF_PLUGIN_CACHE_DIR:-}" ]; then
  export TF_PLUGIN_CACHE_DIR="/tmp/terraform-plugin-cache"
fi
mkdir -p "$TF_PLUGIN_CACHE_DIR" || true

terraform init -input=false -upgrade

echo "===== [2] Terraform validate ====="
terraform validate

echo "===== [3] Terraform plan ====="
PLAN_ARGS=(-refresh=false -out=tfplan.binary)

# Only use terraform.tfvars if it exists
if [ -f "terraform.tfvars" ]; then
  PLAN_ARGS+=(-var-file="terraform.tfvars")
fi

terraform plan "${PLAN_ARGS[@]}"

echo
echo "===== [4] Export plan to JSON ====="
terraform show -json tfplan.binary > tfplan.json

# Do not stop the script if scanners fail
set +e

# Filenames expected by aggregator (scenario root)
CHK_TF_ROOT="checkov_${SCENARIO_NAME}.txt"
TFSEC_ROOT="tfsec_${SCENARIO_NAME}.txt"
TERRASCAN_ROOT="terrascan_${SCENARIO_NAME}.txt"
CONFTEST_ROOT="conftest_${SCENARIO_NAME}.txt"

echo
echo "===== [5] Checkov ====="
checkov -d . --skip-download 2>&1 | tee "$CHK_TF_ROOT" | tee "${LOG_DIR}/${CHK_TF_ROOT}" >/dev/null
CHECKOV_RC=${PIPESTATUS[0]}

echo
echo "===== [6] tfsec ====="
TFSEC_ARGS=(.)
if [ -f "terraform.tfvars" ]; then
  TFSEC_ARGS+=(--tfvars-file "terraform.tfvars")
fi
tfsec "${TFSEC_ARGS[@]}" 2>&1 | tee "$TFSEC_ROOT" | tee "${LOG_DIR}/${TFSEC_ROOT}" >/dev/null
TFSEC_RC=${PIPESTATUS[0]}

echo
echo "===== [7] Terrascan ====="
terrascan scan -d . --iac-type terraform \
  --skip-dirs "github_conf,scan_logs,.terraform" 2>&1 | tee "$TERRASCAN_ROOT" | tee "${LOG_DIR}/${TERRASCAN_ROOT}" >/dev/null
TERRASCAN_RC=${PIPESTATUS[0]}

echo
echo "===== [8] Conftest ====="
# Resolve policy path relative to repo root (robust)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
conftest test tfplan.json --policy "${REPO_ROOT}/policy/terraform" 2>&1 | tee "$CONFTEST_ROOT" | tee "${LOG_DIR}/${CONFTEST_ROOT}" >/dev/null
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
