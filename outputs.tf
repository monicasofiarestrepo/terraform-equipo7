output "lb_ip_address" {
  description = "IP pública única del balanceador"
  value       = google_compute_global_address.lb_ip.address
}

output "network_name" {
  description = "VPC para templates y MIGs (Mario)"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "Self-link de la VPC"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Subred para MIGs (Mario)"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "Self-link de la subred"
  value       = google_compute_subnetwork.subnet.self_link
}

output "backend_network_tag" {
  description = "Tag obligatorio en instance templates (Mario)"
  value       = var.backend_network_tag
}

output "region" {
  description = "Región del despliegue"
  value       = var.region
}

output "zone" {
  description = "Zona para instancias"
  value       = var.zone
}
