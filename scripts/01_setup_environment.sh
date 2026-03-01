#!/bin/bash
# =============================================================================
# 01_setup_environment.sh
# Initialise gcloud CLI, set project, region, zone & enable required APIs
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# ── Validate gcloud is installed ──────────────────────────────────────────────
if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install"
  exit 1
fi

info "Authenticating with Google Cloud..."
gcloud auth login --quiet || warn "Already authenticated, skipping."

info "Setting active project to: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

info "Setting default region to: ${REGION}"
gcloud config set compute/region "${REGION}"

info "Setting default zone to: ${ZONE}"
gcloud config set compute/zone "${ZONE}"

info "Enabling required GCP APIs (this may take 1-2 minutes)..."
gcloud services enable \
  compute.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  --project="${PROJECT_ID}"

success "Environment setup complete."
echo ""
echo "  Project : ${PROJECT_ID}"
echo "  Region  : ${REGION}"
echo "  Zone    : ${ZONE}"
