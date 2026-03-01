#!/bin/bash
# =============================================================================
# 06_setup_iam.sh
# Create service accounts and bind IAM roles (least-privilege model)
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"

# Update these with actual user/group emails before running
DEVELOPER_EMAIL="developer@example.com"
ADMIN_EMAIL="admin@example.com"
DEVOPS_GROUP="devops-team@example.com"

SA_NAME="web-sa"
SA_DISPLAY="Web VM Service Account"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# ── Create Service Account ────────────────────────────────────────────────────
info "Creating service account: ${SA_NAME}..."
gcloud iam service-accounts create "${SA_NAME}" \
  --display-name="${SA_DISPLAY}" \
  --project="${PROJECT_ID}" 2>/dev/null || warn "Service account ${SA_NAME} already exists."

# ── Bind roles to service account ────────────────────────────────────────────
info "Binding roles/logging.logWriter to ${SA_EMAIL}..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.logWriter" \
  --condition=None --quiet

info "Binding roles/monitoring.metricWriter to ${SA_EMAIL}..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/monitoring.metricWriter" \
  --condition=None --quiet

# ── Bind roles to human users ─────────────────────────────────────────────────
info "Binding roles/compute.viewer to ${DEVELOPER_EMAIL}..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="user:${DEVELOPER_EMAIL}" \
  --role="roles/compute.viewer" \
  --condition=None --quiet

info "Binding roles/compute.admin to ${ADMIN_EMAIL}..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="user:${ADMIN_EMAIL}" \
  --role="roles/compute.admin" \
  --condition=None --quiet

info "Binding roles/logging.viewer to devops group ${DEVOPS_GROUP}..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="group:${DEVOPS_GROUP}" \
  --role="roles/logging.viewer" \
  --condition=None --quiet

success "IAM roles configured."
echo ""
echo "  ${SA_EMAIL}        → roles/logging.logWriter, roles/monitoring.metricWriter"
echo "  ${DEVELOPER_EMAIL} → roles/compute.viewer"
echo "  ${ADMIN_EMAIL}     → roles/compute.admin"
echo "  ${DEVOPS_GROUP}    → roles/logging.viewer"
echo ""
echo "  To review: gcloud projects get-iam-policy ${PROJECT_ID}"
