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

# --- Outputs de Mario (cómputo)

output "mig_produccion_instance_group" {
  description = "Instance group del MIG de producción (para backend service de Mafe)"
  value       = google_compute_region_instance_group_manager.mig_produccion.instance_group
}

output "mig_contingencia_instance_group" {
  description = "Instance group del MIG de contingencia (para backend service de Mafe)"
  value       = google_compute_region_instance_group_manager.mig_contingencia.instance_group
}

output "health_check_produccion_id" {
  description = "ID del health check de producción (para backend service de Mafe)"
  value       = google_compute_health_check.hc_produccion.id
}

output "health_check_contingencia_id" {
  description = "ID del health check de contingencia (para backend service de Mafe)"
  value       = google_compute_health_check.hc_contingencia.id
}
