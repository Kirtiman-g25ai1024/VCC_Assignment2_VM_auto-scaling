#!/bin/bash
# =============================================================================
# 04_create_mig.sh
# Create a Regional Managed Instance Group (MIG) using the instance template
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
MIG_NAME="web-mig"
TEMPLATE_NAME="web-vm-template"
INITIAL_SIZE=2

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

info "Creating Managed Instance Group: ${MIG_NAME} in region ${REGION}..."

gcloud compute instance-groups managed create "${MIG_NAME}" \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --template="${TEMPLATE_NAME}" \
  --size="${INITIAL_SIZE}" \
  --description="Managed Instance Group for web auto-scaling assignment"

info "Waiting for MIG instances to become stable..."
gcloud compute instance-groups managed wait-until "${MIG_NAME}" \
  --stable \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

info "Listing running instances:"
gcloud compute instance-groups managed list-instances "${MIG_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

success "MIG created and stable: ${MIG_NAME}"
echo ""
echo "  MIG Name    : ${MIG_NAME}"
echo "  Region      : ${REGION}"
echo "  Initial Size: ${INITIAL_SIZE}"
