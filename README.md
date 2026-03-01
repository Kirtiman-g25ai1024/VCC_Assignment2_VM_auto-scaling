# 🚀 GCP VM Auto Scaling & Security — Assignment 2

[![GCP](https://img.shields.io/badge/Platform-Google%20Cloud%20Platform-4285F4?style=flat-square&logo=google-cloud)](https://cloud.google.com)
[![Compute Engine](https://img.shields.io/badge/Service-Compute%20Engine-FF6F00?style=flat-square&logo=google-cloud)](https://cloud.google.com/compute)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Shell](https://img.shields.io/badge/Scripts-Bash-1f425f?style=flat-square&logo=gnu-bash)](scripts/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](terraform/)

> **Subject:** Virtualisation and Cloud Computing  
> **Assignment:** 2 — Use a Public Cloud Service to Create a VM, Leverage Auto Scaling and Security  
> **Platform:** Google Cloud Platform (GCP)

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Step-by-Step Guide](#step-by-step-guide)
  - [1. Environment Setup](#1-environment-setup)
  - [2. Create Base VM](#2-create-base-vm)
  - [3. Create Instance Template](#3-create-instance-template)
  - [4. Create Managed Instance Group](#4-create-managed-instance-group)
  - [5. Configure Auto Scaling](#5-configure-auto-scaling)
  - [6. Setup IAM & Security](#6-setup-iam--security)
  - [7. Configure Firewall Rules](#7-configure-firewall-rules)
  - [8. Setup Load Balancer](#8-setup-load-balancer)
  - [9. Test Auto Scaling](#9-test-auto-scaling)
  - [10. Cleanup](#10-cleanup)
- [Terraform (IaC)](#terraform-iac)
- [Security Summary](#security-summary)
- [Video Demo](#video-demo)
- [Contributing](#contributing)
- [License](#license)

---

## 📌 Project Overview

This project demonstrates a **production-grade, auto-scaling and secured cloud infrastructure** deployed on **Google Cloud Platform**. It provisions VM instances via Compute Engine, groups them in a **Managed Instance Group (MIG)** with dynamic CPU-based scaling, and secures the environment using **IAM roles**, **VPC firewall rules**, and **service accounts**.

### Key Features

| Feature | Implementation |
|---|---|
| **Auto Scaling** | MIG Autoscaler — scales out at 70% CPU, scales in at 30% CPU |
| **High Availability** | Minimum 2 instances always running across zones |
| **IAM Security** | Least-privilege roles; dedicated service accounts per component |
| **Network Security** | VPC firewall rules; SSH restricted to trusted IP ranges |
| **Load Balancing** | Global HTTP(S) Load Balancer with health checks |
| **Infrastructure as Code** | Full Terraform implementation included |
| **Monitoring** | Cloud Monitoring + Cloud Logging integration |

---

## 🏗️ Architecture

```
                        ┌─────────────────────────────────────────────┐
                        │            INTERNET USERS                    │
                        └────────────────────┬────────────────────────┘
                                             │
                        ┌────────────────────▼────────────────────────┐
                        │     Global HTTP(S) Load Balancer             │
                        │         (Forwarding Rule :80/:443)           │
                        └────────────────────┬────────────────────────┘
                                             │
                        ┌────────────────────▼────────────────────────┐
                        │         Backend Service + Health Checks      │
                        │         (Health Check: TCP:80 every 10s)     │
                        └────────────────────┬────────────────────────┘
                                             │
                        ┌────────────────────▼────────────────────────┐
                        │      Managed Instance Group (MIG)            │
                        │   web-mig  |  us-central1  |  min:2 max:10  │
                        │ ┌────────┐  ┌────────┐  ┌─────────────────┐ │
                        │ │  VM-1  │  │  VM-2  │  │  VM-N (scaled)  │ │
                        │ │Apache  │  │Apache  │  │     Apache      │ │
                        │ └────────┘  └────────┘  └─────────────────┘ │
                        │         CPU > 70% → Scale OUT                │
                        │         CPU < 30% → Scale IN                 │
                        └────────────────────┬────────────────────────┘
                                             │
                   ┌─────────────────────────┴──────────────────────────┐
                   │                                                      │
     ┌─────────────▼─────────────┐                    ┌─────────────────▼──────────────┐
     │   VPC Network + Firewall  │                    │    IAM + Service Accounts       │
     │  ✅ TCP:80   (0.0.0.0/0)  │                    │  web-sa → logging.logWriter      │
     │  ✅ TCP:443  (0.0.0.0/0)  │                    │  web-sa → monitoring.metricWriter│
     │  ✅ TCP:22   (Corp IP /24) │                    │  developer → compute.viewer      │
     │  ❌ ALL other (DENY)      │                    │  admin    → compute.admin        │
     └───────────────────────────┘                    └────────────────────────────────┘
```

---

## ✅ Prerequisites

Before running any scripts, ensure the following are in place:

- [ ] A **Google Cloud Platform account** with billing enabled
- [ ] A **GCP Project** created — note your `PROJECT_ID`
- [ ] **Google Cloud SDK** installed: [Install Guide](https://cloud.google.com/sdk/docs/install)
- [ ] **Terraform ≥ 1.5.0** installed (for IaC): [Install Guide](https://developer.hashicorp.com/terraform/install)
- [ ] Authenticated via `gcloud auth login`
- [ ] IAM Permission: **Project Editor** or **Owner** on the GCP project

---

## 📁 Repository Structure

```
gcp-autoscaling-security/
│
├── 📄 README.md                        ← This file
├── 📄 LICENSE                          ← MIT License
├── 📄 .gitignore                       ← Git ignore rules
│
├── 📂 scripts/                         ← Bash deployment scripts (ordered)
│   ├── 01_setup_environment.sh         ← Init gcloud, enable APIs
│   ├── 02_create_base_vm.sh            ← Create base VM with startup script
│   ├── 03_create_instance_template.sh  ← Package VM as instance template
│   ├── 04_create_mig.sh                ← Create Managed Instance Group
│   ├── 05_configure_autoscaling.sh     ← Set CPU-based autoscaling policy
│   ├── 06_setup_iam.sh                 ← Create service accounts & bind roles
│   ├── 07_configure_firewall.sh        ← VPC firewall rules
│   ├── 08_setup_load_balancer.sh       ← Global LB, backend, forwarding rules
│   ├── 09_test_autoscaling.sh          ← Load test & monitor scaling behavior
│   └── 10_cleanup.sh                   ← Delete all provisioned resources
│
├── 📂 terraform/                       ← Terraform IaC (alternative to scripts)
│   ├── main.tf                         ← Core resource definitions
│   ├── variables.tf                    ← Input variables
│   ├── outputs.tf                      ← Output values
│   └── terraform.tfvars.example        ← Variable values template
│
├── 📂 config/
│   └── startup-script.sh              ← VM startup script (Apache + stress)
│
├── 📂 docs/
│   └── architecture.md                ← Detailed architecture documentation
│
└── 📂 .github/
    └── workflows/
        └── validate.yml               ← CI: validate shell scripts & Terraform
```

---

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-username/gcp-autoscaling-security.git
cd gcp-autoscaling-security

# 2. Make all scripts executable
chmod +x scripts/*.sh

# 3. Set your project ID in the environment
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"

# 4. Run scripts in order
./scripts/01_setup_environment.sh
./scripts/02_create_base_vm.sh
./scripts/03_create_instance_template.sh
./scripts/04_create_mig.sh
./scripts/05_configure_autoscaling.sh
./scripts/06_setup_iam.sh
./scripts/07_configure_firewall.sh
./scripts/08_setup_load_balancer.sh

# 5. Test auto scaling
./scripts/09_test_autoscaling.sh

# 6. Cleanup when done
./scripts/10_cleanup.sh
```

---

## 📖 Step-by-Step Guide

### 1. Environment Setup

Initialise gcloud, set the active project, and enable required GCP APIs.

```bash
./scripts/01_setup_environment.sh
```

What it does:
- Authenticates gcloud CLI
- Sets the active project, region, and zone
- Enables `compute.googleapis.com`, `iam.googleapis.com`, `cloudresourcemanager.googleapis.com`

---

### 2. Create Base VM

Creates a base VM running Debian 11 with Apache and the `stress` tool via a startup script.

```bash
./scripts/02_create_base_vm.sh
```

Key parameters:
| Parameter | Value |
|---|---|
| Machine Type | `e2-medium` (2 vCPU, 4 GB RAM) |
| OS | Debian GNU/Linux 11 (Bullseye) |
| Boot Disk | 20 GB SSD |
| Zone | `us-central1-a` |
| Tags | `http-server`, `https-server` |

---

### 3. Create Instance Template

Packages the VM configuration into a reusable **Instance Template** for the MIG.

```bash
./scripts/03_create_instance_template.sh
```

---

### 4. Create Managed Instance Group

Creates a **Regional Managed Instance Group** (web-mig) with 2 initial instances.

```bash
./scripts/04_create_mig.sh
```

---

### 5. Configure Auto Scaling

Attaches an **Autoscaler** to the MIG with CPU-based scaling policies.

```bash
./scripts/05_configure_autoscaling.sh
```

| Policy | Value |
|---|---|
| Minimum Replicas | 2 |
| Maximum Replicas | 10 |
| Scale-Out Trigger | CPU utilisation > **70%** |
| Scale-In Trigger | CPU utilisation < **30%** |
| Cool-Down Period | 90 seconds |
| Scale-In Control | Max 2 VMs removed per 120s window |

---

### 6. Setup IAM & Security

Creates service accounts and binds IAM roles following **least-privilege**.

```bash
./scripts/06_setup_iam.sh
```

| Principal | Role | Purpose |
|---|---|---|
| `web-sa` (Service Account) | `roles/logging.logWriter` | VMs write logs |
| `web-sa` (Service Account) | `roles/monitoring.metricWriter` | VMs write metrics |
| `developer@example.com` | `roles/compute.viewer` | Read-only Compute access |
| `admin@example.com` | `roles/compute.admin` | Full Compute management |
| `devops-team@` | `roles/logging.viewer` | Log access for debugging |

---

### 7. Configure Firewall Rules

Sets up **VPC firewall rules** to control inbound/outbound traffic.

```bash
./scripts/07_configure_firewall.sh
```

| Rule | Action | Port | Source |
|---|---|---|---|
| `allow-http` | ✅ ALLOW | TCP:80 | `0.0.0.0/0` |
| `allow-https` | ✅ ALLOW | TCP:443 | `0.0.0.0/0` |
| `allow-ssh-restricted` | ✅ ALLOW | TCP:22 | `203.0.113.0/24` (corp only) |
| `allow-lb-health-check` | ✅ ALLOW | TCP:80 | GCP LB IP ranges |
| `deny-all-ingress` | ❌ DENY | ALL | `0.0.0.0/0` |

---

### 8. Setup Load Balancer

Creates a **Global HTTP(S) Load Balancer** connected to the MIG backend.

```bash
./scripts/08_setup_load_balancer.sh
```

Components created: Health Check → Backend Service → URL Map → Target HTTP Proxy → Forwarding Rule

---

### 9. Test Auto Scaling

SSHs into a VM, runs the `stress` tool, and monitors scaling decisions.

```bash
./scripts/09_test_autoscaling.sh
```

Expected behavior:
1. CPU spikes above 70% → Autoscaler triggers scale-out
2. New VMs are provisioned from the instance template
3. Load stops → CPU drops below 30% → Scale-in begins (gradually)

---

### 10. Cleanup

Deletes all provisioned GCP resources to avoid ongoing charges.

```bash
./scripts/10_cleanup.sh
```

> ⚠️ **Warning:** This will permanently delete all resources created by this project.

---

## 🏗️ Terraform (IaC)

An equivalent **Terraform** implementation is provided in the `terraform/` directory.

```bash
cd terraform

# Initialise Terraform
terraform init

# Copy and fill in variable values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id, region, etc.

# Preview the execution plan
terraform plan

# Apply the infrastructure
terraform apply

# Destroy when done
terraform destroy
```

---

## 🔐 Security Summary

| Layer | Measure | Benefit |
|---|---|---|
| **IAM** | Least-privilege roles | Prevents unauthorised access |
| **IAM** | Dedicated service account per component | No shared credentials |
| **Network** | Firewall: allow HTTP/HTTPS only | Reduces attack surface |
| **Network** | SSH restricted to corporate IP range | Blocks internet SSH brute-force |
| **Network** | Explicit deny-all ingress (priority 65534) | Zero-trust default posture |
| **Compute** | Scoped service account on VMs | VMs only access needed APIs |
| **Monitoring** | Cloud Logging + Monitoring enabled | Full audit trail & alerts |

---

## 🎬 Video Demo

📽️ **Demo Link:** [https://drive.google.com/your-video-link-here](https://drive.google.com/your-video-link-here)

> The demo covers: VM creation → MIG setup → Autoscaling policy → IAM config → Firewall rules → Live scaling test

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss the proposed changes.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add: your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

> **Author:** Your Name | **Subject:** Virtualisation and Cloud Computing | **Date:** March 2026
