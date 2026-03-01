#!/bin/bash
# =============================================================================
# 07_configure_firewall.sh
# Create VPC firewall rules: allow HTTP/HTTPS/SSH (restricted), deny all else
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
NETWORK="default"
# Update CORP_IP_RANGE to your organisation's IP range before running
CORP_IP_RANGE="203.0.113.0/24"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

create_rule() {
  local NAME="$1"; shift
  info "Creating firewall rule: ${NAME}..."
  gcloud compute firewall-rules create "${NAME}" \
    --project="${PROJECT_ID}" \
    --network="${NETWORK}" \
    "$@" 2>/dev/null || info "Rule ${NAME} already exists — skipping."
}

# ── Allow HTTP ────────────────────────────────────────────────────────────────
create_rule "allow-http" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --priority=1000 \
  --description="Allow inbound HTTP on port 80"

# ── Allow HTTPS ───────────────────────────────────────────────────────────────
create_rule "allow-https" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server \
  --priority=1000 \
  --description="Allow inbound HTTPS on port 443"

# ── Allow SSH from corporate IP only ─────────────────────────────────────────
create_rule "allow-ssh-restricted" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:22 \
  --source-ranges="${CORP_IP_RANGE}" \
  --target-tags=http-server \
  --priority=900 \
  --description="Allow SSH only from corporate network ${CORP_IP_RANGE}"

# ── Allow GCP Load Balancer health checks ────────────────────────────────────
create_rule "allow-lb-health-check" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=lb-health-check \
  --priority=800 \
  --description="Allow GCP Load Balancer health check probes"

# ── Deny all other ingress (catch-all) ───────────────────────────────────────
create_rule "deny-all-ingress" \
  --action=DENY \
  --direction=INGRESS \
  --rules=all \
  --source-ranges=0.0.0.0/0 \
  --priority=65534 \
  --description="Deny all other ingress — zero-trust default"

success "All firewall rules created."
echo ""
echo "  To list rules: gcloud compute firewall-rules list --filter='name~allow OR name~deny'"
