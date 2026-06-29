# Mario — Cómputo y contenido
#
# Recursos a implementar:
#   - google_compute_instance_template (produccion)
#   - google_compute_instance_template (contingencia)
#   - google_compute_region_instance_group_manager (mig-produccion)
#   - google_compute_region_instance_group_manager (mig-contingencia)
#   - google_compute_health_check (hc-produccion)
#   - google_compute_health_check (hc-contingencia)
#
# Referencias de Moni (usar variables, no hardcodear):
#   - network: var.network_name  o  google_compute_network.vpc.name
#   - subred:  google_compute_subnetwork.subnet.name
#   - region:  var.region
#   - zone:    var.zone
#   - tags:    [var.backend_network_tag]
#
# Nombres acordados (ver CONVENCIONES.txt):
#   - ${var.name_prefix}-tpl-produccion
#   - ${var.name_prefix}-tpl-contingencia
#   - ${var.name_prefix}-mig-produccion
#   - ${var.name_prefix}-mig-contingencia
#   - ${var.name_prefix}-hc-produccion
#   - ${var.name_prefix}-hc-contingencia
#
# Outputs que Mafe necesita (añadir en outputs.tf):
#   - mig_produccion_instance_group
#   - mig_contingencia_instance_group
#   - health_check_produccion_id
#   - health_check_contingencia_id
