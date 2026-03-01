#!/bin/bash
# =============================================================================
# 03_create_instance_template.sh
# Create a GCP Instance Template from the base VM configuration
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
TEMPLATE_NAME="web-vm-template"
MACHINE_TYPE="e2-medium"
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"
DISK_SIZE="20GB"
SERVICE_ACCOUNT="web-sa@${PROJECT_ID}.iam.gserviceaccount.com"
STARTUP_SCRIPT="$(dirname "$0")/../config/startup-script.sh"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

info "Creating instance template: ${TEMPLATE_NAME}..."

gcloud compute instance-templates create "${TEMPLATE_NAME}" \
  --project="${PROJECT_ID}" \
  --machine-type="${MACHINE_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --boot-disk-size="${DISK_SIZE}" \
  --boot-disk-type="pd-ssd" \
  --tags="http-server,https-server,lb-health-check" \
  --metadata-from-file="startup-script=${STARTUP_SCRIPT}" \
  --service-account="${SERVICE_ACCOUNT}" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" \
  --description="Instance template for web-mig auto-scaling group"

success "Instance template created: ${TEMPLATE_NAME}"
echo ""
echo "  To verify: gcloud compute instance-templates describe ${TEMPLATE_NAME}"
