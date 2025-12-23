#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SUITE_DIR="${ROOT_DIR}/test-suite"
RESULTS_DIR="${ROOT_DIR}/results"
LOG_DIR="${RESULTS_DIR}/logs"

mkdir -p "${LOG_DIR}"

TS="$(date -u '+%Y%m%d_%H%M%S')"
EXPERIMENT_LOG="${LOG_DIR}/FULL_EXPERIMENT_${TS}.log"

# Log everything (stdout+stderr) into the experiment log
exec > >(tee -a "${EXPERIMENT_LOG}") 2>&1

echo "============================================================"
echo "EXPERIMENT START: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "ROOT_DIR: ${ROOT_DIR}"
echo "TEST_SUITE_DIR: ${TEST_SUITE_DIR}"
echo "RESULTS_DIR: ${RESULTS_DIR}"
echo "EXPERIMENT_LOG: ${EXPERIMENT_LOG}"
echo "============================================================"
echo

mapfile -t SCENARIOS < <(
  find "${TEST_SUITE_DIR}" -type f -name "scenario.json" -print0 \
  | xargs -0 -n1 dirname \
  | sort
)

echo "Found ${#SCENARIOS[@]} scenarios"
echo

for SCENARIO in "${SCENARIOS[@]}"; do
  echo "------------------------------------------------------------"
  echo "Running scenario: ${SCENARIO}"
  echo "------------------------------------------------------------"

  "${ROOT_DIR}/run_scans.sh" "${SCENARIO}" || true
  echo
done

echo "============================================================"
echo "EXPERIMENT END: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "============================================================"

exit 0
