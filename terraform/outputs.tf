output "load_balancer_ip" {
  description = "The IP address of the Global HTTP Load Balancer"
  value       = google_compute_global_forwarding_rule.web_forwarding.ip_address
}

output "mig_name" {
  description = "Name of the Managed Instance Group"
  value       = google_compute_region_instance_group_manager.web_mig.name
}

output "service_account_email" {
  description = "Email of the VM service account"
  value       = google_service_account.web_sa.email
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.web_template.name
}
