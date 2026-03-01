#!/bin/bash
# =============================================================================
# 05_configure_autoscaling.sh
# Attach a CPU-utilisation-based autoscaler to the Managed Instance Group
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
MIG_NAME="web-mig"

MIN_REPLICAS=2
MAX_REPLICAS=10
TARGET_CPU_UTIL=0.70       # Scale out above 70% CPU
COOL_DOWN_PERIOD=90        # Seconds to wait after scaling before re-evaluating
MAX_SCALE_IN_REPLICAS=2    # Max VMs to remove per scale-in window
SCALE_IN_WINDOW_SEC=120    # Scale-in evaluation window in seconds

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

info "Configuring autoscaler on MIG: ${MIG_NAME}..."

gcloud compute instance-groups managed set-autoscaling "${MIG_NAME}" \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --min-num-replicas="${MIN_REPLICAS}" \
  --max-num-replicas="${MAX_REPLICAS}" \
  --target-cpu-utilization="${TARGET_CPU_UTIL}" \
  --cool-down-period="${COOL_DOWN_PERIOD}" \
  --scale-in-control="max-scaled-in-replicas=${MAX_SCALE_IN_REPLICAS},time-window=${SCALE_IN_WINDOW_SEC}" \
  --mode="on"

info "Verifying autoscaler configuration..."
gcloud compute instance-groups managed describe-autoscaling "${MIG_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

success "Autoscaler configured on ${MIG_NAME}."
echo ""
echo "  Min Replicas     : ${MIN_REPLICAS}"
echo "  Max Replicas     : ${MAX_REPLICAS}"
echo "  Scale-Out @ CPU  : $(echo "${TARGET_CPU_UTIL} * 100" | bc)%"
echo "  Cool-Down Period : ${COOL_DOWN_PERIOD}s"
echo "  Scale-In Control : max ${MAX_SCALE_IN_REPLICAS} VMs per ${SCALE_IN_WINDOW_SEC}s window"
