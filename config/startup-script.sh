#!/bin/bash
# =============================================================================
# startup-script.sh
# GCP VM Startup Script — Installs Apache2 and Stress Tool
# Used by: Instance Template (web-vm-template)
# =============================================================================

set -euo pipefail

LOG_FILE="/var/log/startup-script.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting VM startup script..."

# Update package lists
log "Updating package lists..."
apt-get update -y >> "$LOG_FILE" 2>&1

# Install Apache2 web server
log "Installing Apache2..."
apt-get install -y apache2 >> "$LOG_FILE" 2>&1

# Install stress tool for load testing
log "Installing stress tool..."
apt-get install -y stress >> "$LOG_FILE" 2>&1

# Enable and start Apache
log "Enabling and starting Apache2..."
systemctl enable apache2
systemctl start apache2

# Retrieve hostname and metadata for the index page
HOSTNAME=$(hostname)
INSTANCE_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/id" \
  -H "Metadata-Flavor: Google" 2>/dev/null || echo "unknown")
ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" \
  -H "Metadata-Flavor: Google" 2>/dev/null | awk -F/ '{print $NF}' || echo "unknown")
MACHINE_TYPE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/machine-type" \
  -H "Metadata-Flavor: Google" 2>/dev/null | awk -F/ '{print $NF}' || echo "unknown")

# Create a custom index.html
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>GCP Auto Scaling Demo</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f0f4f8; display: flex;
               justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: white; padding: 2rem 3rem; border-radius: 12px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1); max-width: 500px; width: 100%; }
        h1 { color: #1a56db; margin-top: 0; }
        .badge { display: inline-block; background: #dbeafe; color: #1e3a5f;
                 padding: 4px 12px; border-radius: 20px; font-size: 0.85rem; margin-bottom: 1rem; }
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
        th { background: #1e3a5f; color: white; padding: 8px 12px; text-align: left; }
        td { padding: 8px 12px; border-bottom: 1px solid #e5e7eb; }
        tr:nth-child(even) { background: #f9fafb; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">✅ Auto Scaling Active</span>
        <h1>Hello from GCP!</h1>
        <p>This instance is part of a Managed Instance Group with CPU-based auto scaling.</p>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Hostname</td><td><strong>${HOSTNAME}</strong></td></tr>
            <tr><td>Instance ID</td><td>${INSTANCE_ID}</td></tr>
            <tr><td>Zone</td><td>${ZONE}</td></tr>
            <tr><td>Machine Type</td><td>${MACHINE_TYPE}</td></tr>
        </table>
    </div>
</body>
</html>
EOF

log "index.html created successfully."

# Create a simple health check endpoint
mkdir -p /var/www/html/health
echo "OK" > /var/www/html/health/index.html

log "Startup script completed successfully."
