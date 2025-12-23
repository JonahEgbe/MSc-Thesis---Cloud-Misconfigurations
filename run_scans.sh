#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# Usage: ./run_scans.sh <scenario-dir>
# --------------------------------------------------

SCENARIO_DIR="${1:-}"
if [[ -z "${SCENARIO_DIR}" || ! -d "${SCENARIO_DIR}" ]]; then
  echo "Usage: $0 <scenario-dir>"
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO_DIR="$(cd "${SCENARIO_DIR}" && pwd)"
SCENARIO_NAME="$(basename "${SCENARIO_DIR}")"

POLICY_DIR="${ROOT_DIR}/policy/terraform"

LOG_DIR="${SCENARIO_DIR}/scan_logs"
mkdir -p "${LOG_DIR}"

MASTER_LOG="${LOG_DIR}/FULL_${SCENARIO_NAME}.log"
TFPLAN_BIN="${SCENARIO_DIR}/tfplan.binary"
TFPLAN_JSON="${SCENARIO_DIR}/tfplan.json"

CHECKOV_OUT="${LOG_DIR}/checkov_${SCENARIO_NAME}.txt"
TFSEC_OUT="${LOG_DIR}/tfsec_${SCENARIO_NAME}.txt"
TERRASCAN_OUT="${LOG_DIR}/terrascan_${SCENARIO_NAME}.txt"
CONFTEST_OUT="${LOG_DIR}/conftest_${SCENARIO_NAME}.txt"

# Log everything (stdout+stderr) into the scenario master log
exec > >(tee -a "${MASTER_LOG}") 2>&1

echo "============================================================"
echo "FULL SCAN START: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Scenario: ${SCENARIO_NAME}"
echo "Path: ${SCENARIO_DIR}"
echo "Policy: ${POLICY_DIR}"
echo "============================================================"
echo

cd "${SCENARIO_DIR}"

# --------------------------------------------------
# Terraform
# --------------------------------------------------
terraform init -input=false -no-color
terraform validate -no-color

PLAN_ARGS=(plan -input=false -no-color -out "${TFPLAN_BIN}")
if [[ -f terraform.tfvars ]]; then
  PLAN_ARGS+=( -var-file=terraform.tfvars )
fi
terraform "${PLAN_ARGS[@]}"

terraform show -json "${TFPLAN_BIN}" > "${TFPLAN_JSON}"

# --------------------------------------------------
# Scanners (findings allowed; do not fail experiment)
# --------------------------------------------------
set +e

# Checkov against tfplan.json
checkov -f "tfplan.json" -o cli > "${CHECKOV_OUT}" 2>&1
rc_checkov=$?

# tfsec: scan current directory, but include tfvars when present
if [[ -f terraform.tfvars ]]; then
  tfsec . --tfvars-file terraform.tfvars > "${TFSEC_OUT}" 2>&1
else
  tfsec . > "${TFSEC_OUT}" 2>&1
fi
rc_tfsec=$?

# Terrascan: scan current directory, skip scan_logs + .terraform
terrascan scan -i terraform -t aws -d . -o human --skip-dirs "scan_logs,.terraform" > "${TERRASCAN_OUT}" 2>&1
rc_terrascan=$?

# Conftest: exact style (tfplan.json + policy/terraform/)
conftest test tfplan.json --policy "${POLICY_DIR}/" > "${CONFTEST_OUT}" 2>&1
rc_conftest=$?

set -e

echo
echo "============================================================"
echo "FULL SCAN END: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Return codes (non-fatal):"
echo "  checkov   = ${rc_checkov}"
echo "  tfsec     = ${rc_tfsec}"
echo "  terrascan = ${rc_terrascan}"
echo "  conftest  = ${rc_conftest}"
echo "Outputs:"
echo "  ${CHECKOV_OUT}"
echo "  ${TFSEC_OUT}"
echo "  ${TERRASCAN_OUT}"
echo "  ${CONFTEST_OUT}"
echo "Master log:"
echo "  ${MASTER_LOG}"
echo "============================================================"

exit 0
