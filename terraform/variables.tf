variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for base VM"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine machine type for VM instances"
  type        = string
  default     = "e2-medium"
}

variable "developer_email" {
  description = "Email of the developer user (granted compute.viewer)"
  type        = string
  default     = "developer@example.com"
}

variable "admin_email" {
  description = "Email of the admin user (granted compute.admin)"
  type        = string
  default     = "admin@example.com"
}

variable "corp_ip_range" {
  description = "Corporate IP CIDR range allowed SSH access"
  type        = string
  default     = "203.0.113.0/24"
}
