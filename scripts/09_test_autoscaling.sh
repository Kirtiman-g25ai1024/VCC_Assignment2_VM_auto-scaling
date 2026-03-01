#!/bin/bash
# =============================================================================
# 09_test_autoscaling.sh
# SSH into a MIG VM, run the stress tool, and monitor auto-scaling in real time
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"
MIG_NAME="web-mig"
STRESS_DURATION=300   # Stress duration in seconds (5 min)
POLL_INTERVAL=15      # Seconds between monitoring polls

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# ── Get a target VM from the MIG ─────────────────────────────────────────────
info "Fetching an instance from MIG: ${MIG_NAME}..."
TARGET_VM=$(gcloud compute instance-groups managed list-instances "${MIG_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(name)" | head -1)

if [[ -z "${TARGET_VM}" ]]; then
  echo "ERROR: No instances found in ${MIG_NAME}. Ensure the MIG is running."
  exit 1
fi

TARGET_ZONE=$(gcloud compute instances list \
  --filter="name=${TARGET_VM}" \
  --project="${PROJECT_ID}" \
  --format="value(zone)" | awk -F/ '{print $NF}')

info "Target VM: ${TARGET_VM} in zone ${TARGET_ZONE}"
info "Starting CPU stress test for ${STRESS_DURATION} seconds..."

# ── Run stress in background via gcloud SSH ───────────────────────────────────
gcloud compute ssh "${TARGET_VM}" \
  --zone="${TARGET_ZONE}" \
  --project="${PROJECT_ID}" \
  --command="nohup stress --cpu 2 --timeout ${STRESS_DURATION} > /tmp/stress.log 2>&1 &" \
  --quiet

success "Stress tool launched on ${TARGET_VM}."
echo ""
info "Monitoring autoscaler decisions every ${POLL_INTERVAL}s. Press Ctrl+C to stop watching."
echo ""

# ── Monitor MIG instance count ────────────────────────────────────────────────
INITIAL_COUNT=$(gcloud compute instance-groups managed describe "${MIG_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="get(targetSize)")

echo "  Initial instance count: ${INITIAL_COUNT}"
echo ""

for i in $(seq 1 $((STRESS_DURATION / POLL_INTERVAL))); do
  CURRENT_COUNT=$(gcloud compute instance-groups managed describe "${MIG_NAME}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --format="get(targetSize)")

  AUTOSCALER_STATUS=$(gcloud compute instance-groups managed describe-autoscaling "${MIG_NAME}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --format="get(autoscalingPolicy.mode)" 2>/dev/null || echo "UNKNOWN")

  TIMESTAMP=$(date '+%H:%M:%S')
  if [[ "${CURRENT_COUNT}" -gt "${INITIAL_COUNT}" ]]; then
    echo -e "  [${TIMESTAMP}] ${GREEN}↑ SCALE OUT${NC} — Instances: ${CURRENT_COUNT} (was ${INITIAL_COUNT})"
  elif [[ "${CURRENT_COUNT}" -lt "${INITIAL_COUNT}" ]]; then
    echo -e "  [${TIMESTAMP}] ${YELLOW}↓ SCALE IN${NC}  — Instances: ${CURRENT_COUNT} (was ${INITIAL_COUNT})"
  else
    echo -e "  [${TIMESTAMP}] ${BLUE}→ STABLE${NC}    — Instances: ${CURRENT_COUNT}"
  fi

  sleep "${POLL_INTERVAL}"
done

success "Stress test duration complete. Monitor Cloud Monitoring for scale-in activity."
echo ""
echo "  Cloud Monitoring URL:"
echo "  https://console.cloud.google.com/monitoring/metrics-explorer?project=${PROJECT_ID}"
