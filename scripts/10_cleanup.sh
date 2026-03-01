#!/bin/bash
# =============================================================================
# 10_cleanup.sh
# Delete ALL resources created by this assignment to avoid ongoing charges
# ⚠️  WARNING: This is IRREVERSIBLE. All data will be lost.
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
delete()  { echo -e "${RED}[DELETE]${NC} $1"; }

echo -e "${RED}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  ⚠️  WARNING: This will DELETE all GCP resources!    ║"
echo "  ║  Project: ${PROJECT_ID}"
echo "  ║  This action is IRREVERSIBLE.                        ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

read -rp "Type 'DELETE' to confirm: " CONFIRM
if [[ "${CONFIRM}" != "DELETE" ]]; then
  echo "Aborted."
  exit 0
fi

delete "Removing global forwarding rule..."
gcloud compute forwarding-rules delete web-forwarding-rule \
  --global --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Removing target HTTP proxy..."
gcloud compute target-http-proxies delete web-proxy \
  --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Removing URL map..."
gcloud compute url-maps delete web-url-map \
  --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Removing backend service..."
gcloud compute backend-services delete web-backend \
  --global --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Removing health check..."
gcloud compute health-checks delete web-health-check \
  --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Deleting Managed Instance Group: web-mig..."
gcloud compute instance-groups managed delete web-mig \
  --region="${REGION}" --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Deleting instance template: web-vm-template..."
gcloud compute instance-templates delete web-vm-template \
  --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Deleting base VM: base-web-vm..."
gcloud compute instances delete base-web-vm \
  --zone="${ZONE}" --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Not found."

delete "Removing firewall rules..."
for RULE in allow-http allow-https allow-ssh-restricted allow-lb-health-check deny-all-ingress; do
  gcloud compute firewall-rules delete "${RULE}" \
    --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "${RULE} not found."
done

delete "Removing IAM bindings for service account: web-sa..."
gcloud iam service-accounts delete \
  "web-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" --quiet 2>/dev/null || warn "Service account not found."

success "Cleanup complete. All resources deleted."
