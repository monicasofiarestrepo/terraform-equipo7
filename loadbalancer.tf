# Mafe — Balanceo y control de tráfico por pesos
#
# Recursos a implementar:
#   - google_compute_backend_service (backend-produccion)
#   - google_compute_backend_service (backend-contingencia)
#   - google_compute_url_map (con weighted_backend_services)
#   - google_compute_target_http_proxy
#   - google_compute_global_forwarding_rule
#
# Referencias de Moni:
#   - IP pública: google_compute_global_address.lb_ip.address
#
# Referencias de Mario (cuando existan):
#   - backend.group = <mig instance group self_link>
#   - health_checks = [<health_check self_link>]
#
# Variables de peso (ya en variables.tf):
#   - var.weight_produccion
#   - var.weight_contingencia
#
# Nombres acordados (ver CONVENCIONES.txt):
#   - ${var.name_prefix}-backend-produccion
#   - ${var.name_prefix}-backend-contingencia
#   - ${var.name_prefix}-url-map
#   - ${var.name_prefix}-http-proxy
#   - ${var.name_prefix}-forwarding-rule
#
# Escenarios en terraform.tfvars (pesos 0-1000):
#   100% / 0%   -> 1000 / 0
#   0% / 100%   -> 0 / 1000
#   50% / 50%   -> 500 / 500
