#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
TEST_SUITE_DIR="${ROOT_DIR}/test-suite"
RESULTS_DIR="${ROOT_DIR}/results"

mkdir -p "$RESULTS_DIR"
mkdir -p "${RESULTS_DIR}/logs"

EXPERIMENT_TS="$(date -u +%Y%m%d_%H%M%S)"
EXPERIMENT_LOG="${RESULTS_DIR}/logs/FULL_EXPERIMENT_${EXPERIMENT_TS}.log"

# Print AND capture everything for the full experiment
exec > >(tee -a "$EXPERIMENT_LOG") 2>&1

echo "============================================================"
echo "EXPERIMENT START: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
echo "ROOT_DIR: $ROOT_DIR"
echo "TEST_SUITE_DIR: $TEST_SUITE_DIR"
echo "RESULTS_DIR: $RESULTS_DIR"
echo "EXPERIMENT_LOG: $EXPERIMENT_LOG"
echo "============================================================"
echo

echo "==> Discovering scenarios (folders containing scenario.json)..."
mapfile -t SCENARIO_FILES < <(find "$TEST_SUITE_DIR" -type f -name "scenario.json" | sort)

echo "==> Found ${#SCENARIO_FILES[@]} scenarios."
if [ "${#SCENARIO_FILES[@]}" -eq 0 ]; then
  echo "ERROR: No scenarios found. Check folder structure and scenario.json names."
  exit 1
fi

# Create/overwrite summary header
SUMMARY_CSV="${RESULTS_DIR}/summary.csv"
echo "Scenario_ID,Domain,Type,CIS_Control,Expected,Checkov_Detected,Checkov_HIGH,tfsec_Detected,tfsec_HIGH,Terrascan_Detected,Terrascan_HIGH,Conftest_Detected,Result" > "$SUMMARY_CSV"

for SCENARIO_JSON in "${SCENARIO_FILES[@]}"; do
  SCENARIO_DIR="$(dirname "$SCENARIO_JSON")"

  echo
  echo "============================================================"
  echo "Running scenario: $SCENARIO_DIR"
  echo "============================================================"

  # 1) Run scans (prints full logs and stores in scenario scan_logs/)
  ./run_scans.sh "$SCENARIO_DIR" || true

  # 2) Aggregate into one JSON (your existing script)
  #    IMPORTANT: aggregate_results.py should print JSON to stdout
  AGG_JSON="$(python3 scripts/aggregate_results.py "$SCENARIO_DIR" || true)"

  if [ -z "${AGG_JSON}" ]; then
    echo "WARNING: aggregate_results.py returned empty output for: $SCENARIO_DIR"
    # still continue experiment
    continue
  fi

  # 3) Extract scenario_id safely from JSON (NO jq; reads JSON from stdin)
  SCENARIO_ID="$(printf '%s' "$AGG_JSON" | python3 -c 'import json,sys
try:
  obj=json.load(sys.stdin)
  print(obj.get("scenario_id","UNKNOWN"))
except Exception:
  print("UNKNOWN")
')"

  mkdir -p "${RESULTS_DIR}/${SCENARIO_ID}"
  echo "$AGG_JSON" > "${RESULTS_DIR}/${SCENARIO_ID}/aggregated.json"

  # 4) Append one CSV row robustly (handles commas/newlines safely)
  printf '%s' "$AGG_JSON" | python3 -c 'import json,sys
csv_path=sys.argv[1]

def clean(x):
  if x is None:
    return ""
  if isinstance(x,bool):
    return "TRUE" if x else "FALSE"
  s=str(x)
  s=s.replace("\n"," ").replace("\r"," ")
  s=s.replace(",",";")  # keep CSV structure intact
  return s

try:
  obj=json.load(sys.stdin)
except Exception:
  sys.exit(0)

row = [
  clean(obj.get("scenario_id","")),
  clean(obj.get("domain","")),
  clean(obj.get("type","")),
  clean("|".join(obj.get("cis_controls",[]))),
  clean(obj.get("expected","")),
  clean(obj.get("checkov_detected", False)),
  clean(obj.get("checkov_high","")),
  clean(obj.get("tfsec_detected", False)),
  clean(obj.get("tfsec_high","")),
  clean(obj.get("terrascan_detected", False)),
  clean(obj.get("terrascan_high","")),
  clean(obj.get("conftest_detected", False)),
  clean(obj.get("result","")),
]

with open(csv_path,"a",encoding="utf-8") as f:
  f.write(",".join(row) + "\n")
' "$SUMMARY_CSV"

done

echo
echo "============================================================"
echo "Experiment complete."
echo "➡ Summary: ${SUMMARY_CSV}"
echo "➡ Per-scenario JSON: ${RESULTS_DIR}/<scenario_id>/aggregated.json"
echo "➡ Full experiment log: ${EXPERIMENT_LOG}"
echo "============================================================"
