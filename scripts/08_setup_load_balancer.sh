#!/bin/bash
# =============================================================================
# 08_setup_load_balancer.sh
# Create a Global HTTP(S) Load Balancer connected to the MIG backend
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
MIG_NAME="web-mig"

HEALTH_CHECK="web-health-check"
BACKEND_SERVICE="web-backend"
URL_MAP="web-url-map"
HTTP_PROXY="web-proxy"
FORWARDING_RULE="web-forwarding-rule"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

# ── Step 1: Health Check ──────────────────────────────────────────────────────
info "Creating health check: ${HEALTH_CHECK}..."
gcloud compute health-checks create http "${HEALTH_CHECK}" \
  --project="${PROJECT_ID}" \
  --port=80 \
  --request-path=/index.html \
  --check-interval=10s \
  --timeout=5s \
  --healthy-threshold=2 \
  --unhealthy-threshold=3 \
  --description="HTTP health check for web-mig backend"

# ── Step 2: Backend Service ───────────────────────────────────────────────────
info "Creating backend service: ${BACKEND_SERVICE}..."
gcloud compute backend-services create "${BACKEND_SERVICE}" \
  --project="${PROJECT_ID}" \
  --protocol=HTTP \
  --health-checks="${HEALTH_CHECK}" \
  --global \
  --description="Backend service for web-mig auto-scaling group"

info "Adding MIG backend to backend service..."
gcloud compute backend-services add-backend "${BACKEND_SERVICE}" \
  --project="${PROJECT_ID}" \
  --instance-group="${MIG_NAME}" \
  --instance-group-region="${REGION}" \
  --balancing-mode=UTILIZATION \
  --max-utilization=0.8 \
  --global

# ── Step 3: URL Map ───────────────────────────────────────────────────────────
info "Creating URL map: ${URL_MAP}..."
gcloud compute url-maps create "${URL_MAP}" \
  --project="${PROJECT_ID}" \
  --default-service="${BACKEND_SERVICE}"

# ── Step 4: Target HTTP Proxy ─────────────────────────────────────────────────
info "Creating target HTTP proxy: ${HTTP_PROXY}..."
gcloud compute target-http-proxies create "${HTTP_PROXY}" \
  --project="${PROJECT_ID}" \
  --url-map="${URL_MAP}"

# ── Step 5: Global Forwarding Rule ────────────────────────────────────────────
info "Creating global forwarding rule: ${FORWARDING_RULE}..."
gcloud compute forwarding-rules create "${FORWARDING_RULE}" \
  --project="${PROJECT_ID}" \
  --global \
  --target-http-proxy="${HTTP_PROXY}" \
  --ports=80

info "Waiting for forwarding rule to provision (30s)..."
sleep 30

LB_IP=$(gcloud compute forwarding-rules describe "${FORWARDING_RULE}" \
  --project="${PROJECT_ID}" \
  --global \
  --format="get(IPAddress)")

success "Load Balancer setup complete."
echo ""
echo "  Load Balancer IP : ${LB_IP}"
echo "  Access URL       : http://${LB_IP}"
echo ""
echo "  Note: It may take 2-5 minutes for the LB to fully propagate."
