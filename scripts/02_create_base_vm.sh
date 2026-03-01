#!/bin/bash
# =============================================================================
# 02_create_base_vm.sh
# Create the base VM instance on GCP Compute Engine with Apache + stress
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
ZONE="${ZONE:-us-central1-a}"
VM_NAME="base-web-vm"
MACHINE_TYPE="e2-medium"
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"
DISK_SIZE="20GB"
STARTUP_SCRIPT="$(dirname "$0")/../config/startup-script.sh"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

info "Creating base VM: ${VM_NAME} in zone ${ZONE}..."

gcloud compute instances create "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --boot-disk-size="${DISK_SIZE}" \
  --boot-disk-type="pd-ssd" \
  --tags="http-server,https-server" \
  --metadata-from-file="startup-script=${STARTUP_SCRIPT}" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" \
  --description="Base VM for GCP auto-scaling assignment"

info "Waiting for VM to become RUNNING..."
gcloud compute instances wait-until-running "${VM_NAME}" \
  --zone="${ZONE}" \
  --project="${PROJECT_ID}"

EXTERNAL_IP=$(gcloud compute instances describe "${VM_NAME}" \
  --zone="${ZONE}" \
  --project="${PROJECT_ID}" \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

success "Base VM created successfully."
echo ""
echo "  VM Name     : ${VM_NAME}"
echo "  Zone        : ${ZONE}"
echo "  Machine Type: ${MACHINE_TYPE}"
echo "  External IP : ${EXTERNAL_IP}"
echo ""
echo "  Access via: http://${EXTERNAL_IP}"
echo "  SSH via   : gcloud compute ssh ${VM_NAME} --zone=${ZONE}"
