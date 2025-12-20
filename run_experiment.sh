#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
TEST_SUITE_DIR="${ROOT_DIR}/test-suite"
RESULTS_DIR="${ROOT_DIR}/results"

mkdir -p "$RESULTS_DIR"

echo "==> Discovering scenarios (folders containing scenario.json)..."

# Find ALL scenario.json files anywhere under test-suite
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

  # 1) Run scans (writes tool outputs into scenario folder)
  ./run_scans.sh "$SCENARIO_DIR" || true

  # 2) Aggregate into one JSON (your existing script)
  #    Store per-scenario aggregated output into results/<scenario_id>/aggregated.json
  AGG_JSON="$(python3 scripts/aggregate_results.py "$SCENARIO_DIR")"

  # Extract scenario_id safely (no jq requirement)
  SCENARIO_ID="$(python3 - <<'PY'
import json,sys
obj=json.loads(sys.stdin.read())
print(obj.get("scenario_id","UNKNOWN"))
PY
<<< "$AGG_JSON"
)"

  mkdir -p "${RESULTS_DIR}/${SCENARIO_ID}"
  echo "$AGG_JSON" > "${RESULTS_DIR}/${SCENARIO_ID}/aggregated.json"

  # 3) Also append one CSV row into summary.csv
  python3 - <<'PY' "$SUMMARY_CSV" <<< "$AGG_JSON"
import json,sys
csv_path=sys.argv[1]
obj=json.loads(sys.stdin.read())

row = [
  obj.get("scenario_id",""),
  obj.get("domain",""),
  obj.get("type",""),
  "|".join(obj.get("cis_controls",[])),
  obj.get("expected",""),
  str(obj.get("checkov_detected","")).upper(),
  str(obj.get("checkov_high","")),
  str(obj.get("tfsec_detected","")).upper(),
  str(obj.get("tfsec_high","")),
  str(obj.get("terrascan_detected","")).upper(),
  str(obj.get("terrascan_high","")),
  str(obj.get("conftest_detected","")).upper(),
  obj.get("result","")
]

with open(csv_path,"a",encoding="utf-8") as f:
  f.write(",".join(row) + "\n")
PY

done

echo
echo "Experiment complete."
echo "➡ Summary: ${SUMMARY_CSV}"
echo "➡ Per-scenario JSON: ${RESULTS_DIR}/<scenario_id>/aggregated.json"
