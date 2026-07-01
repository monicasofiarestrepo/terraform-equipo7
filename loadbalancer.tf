# Balanceo y control de tráfico por pesos
#
# Recursos a implementar:
#   - google_compute_backend_service (backend-produccion)
#   - google_compute_backend_service (backend-contingencia)
#   - google_compute_url_map (con weighted_backend_services)
#   - google_compute_target_http_proxy
#   - google_compute_global_forwarding_rule
#
# Referencias:
#   - IP pública: google_compute_global_address.lb_ip.address
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


# ================================================================================
# CONFIGURACIÓN DEL EXTERNAL HTTP LOAD BALANCER CON PESOS
# ================================================================================

# 1. Backend Service para el Servicio Principal (Producción)
resource "google_compute_backend_service" "backend_produccion" {
  name                  = "${var.name_prefix}-backend-produccion"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED" # Obligatorio para Traffic Management avanzado
  timeout_sec           = 30

  backend {
    group = google_compute_region_instance_group_manager.mig_produccion.instance_group
  }

  health_checks = [google_compute_health_check.hc_produccion.id]
}

# 2. Backend Service para el Servicio de Contingencia (Mantenimiento)
resource "google_compute_backend_service" "backend_contingencia" {
  name                  = "${var.name_prefix}-backend-contingencia"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group = google_compute_region_instance_group_manager.mig_contingencia.instance_group
  }

  health_checks = [google_compute_health_check.hc_contingencia.id]
}

# 3. URL Map utilizando route_rules con pesos ponderados (0-1000)
resource "google_compute_url_map" "url_map" {
  name            = "${var.name_prefix}-url-map"
  default_service = google_compute_backend_service.backend_produccion.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "path-matcher"
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.backend_produccion.id

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
      }

      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_produccion.id
          weight          = var.weight_produccion
        }
        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_contingencia.id
          weight          = var.weight_contingencia
        }
      }
    }
  }
}

# 4. Target HTTP Proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.name_prefix}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# 5. Global Forwarding Rule (Punto de Entrada Único)
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.name_prefix}-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = var.backend_port
  target                = google_compute_target_http_proxy.http_proxy.id
}