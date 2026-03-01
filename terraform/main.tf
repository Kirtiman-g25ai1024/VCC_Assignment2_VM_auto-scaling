# =============================================================================
# main.tf — GCP Auto Scaling & Security Infrastructure
# Virtualisation and Cloud Computing — Assignment 2
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ── Service Account ───────────────────────────────────────────────────────────
resource "google_service_account" "web_sa" {
  account_id   = "web-sa"
  display_name = "Web VM Service Account"
  description  = "Least-privilege SA attached to MIG instances"
}

resource "google_project_iam_member" "web_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.web_sa.email}"
}

resource "google_project_iam_member" "web_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.web_sa.email}"
}

# ── IAM: Developer & Admin ────────────────────────────────────────────────────
resource "google_project_iam_member" "developer_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "user:${var.developer_email}"
}

resource "google_project_iam_member" "admin_compute" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "user:${var.admin_email}"
}

# ── Firewall Rules ────────────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  priority      = 1000
  description   = "Allow inbound HTTP on port 80"
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
  priority      = 1000
  description   = "Allow inbound HTTPS on port 443"
}

resource "google_compute_firewall" "allow_ssh_restricted" {
  name    = "allow-ssh-restricted"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.corp_ip_range]
  target_tags   = ["http-server"]
  priority      = 900
  description   = "Allow SSH from corporate network only"
}

resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "allow-lb-health-check"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["lb-health-check"]
  priority      = 800
  description   = "Allow GCP Load Balancer health check probes"
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "deny-all-ingress"
  network = "default"
  deny {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
  description   = "Deny all other ingress — zero-trust default"
}

# ── Instance Template ─────────────────────────────────────────────────────────
resource "google_compute_instance_template" "web_template" {
  name         = "web-vm-template"
  machine_type = var.machine_type
  tags         = ["http-server", "https-server", "lb-health-check"]
  description  = "Instance template for web auto-scaling MIG"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-ssd"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    startup-script = file("${path.module}/../config/startup-script.sh")
  }

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Managed Instance Group ────────────────────────────────────────────────────
resource "google_compute_region_instance_group_manager" "web_mig" {
  name               = "web-mig"
  region             = var.region
  base_instance_name = "web-vm"

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web_health.id
    initial_delay_sec = 120
  }
}

# ── Autoscaler ────────────────────────────────────────────────────────────────
resource "google_compute_region_autoscaler" "web_autoscaler" {
  name   = "web-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.web_mig.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 10
    cooldown_period = 90

    cpu_utilization {
      target = 0.70
    }

    scale_in_control {
      max_scaled_in_replicas {
        fixed = 2
      }
      time_window_sec = 120
    }
  }
}

# ── Health Check ──────────────────────────────────────────────────────────────
resource "google_compute_health_check" "web_health" {
  name = "web-health-check"
  http_health_check {
    port         = 80
    request_path = "/index.html"
  }
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# ── Load Balancer ─────────────────────────────────────────────────────────────
resource "google_compute_backend_service" "web_backend" {
  name          = "web-backend"
  protocol      = "HTTP"
  health_checks = [google_compute_health_check.web_health.id]

  backend {
    group           = google_compute_region_instance_group_manager.web_mig.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
}

resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

resource "google_compute_global_forwarding_rule" "web_forwarding" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
}
