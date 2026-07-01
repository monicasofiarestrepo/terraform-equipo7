# ==============================================================================
# compute.tf (capa de cómputo)
# ==============================================================================
# 2 instance templates + 2 MIGs regionales separados + 2 health checks.
# Producción y contingencia viven en máquinas independientes (aislamiento de
# fallos exigido por la rúbrica).
#
# Sirve HTML por el puerto 80 con python3 (ya viene en la imagen Debian 12),
# así no hace falta instalar nada ni dar IP externa a las VMs.
# ==============================================================================

# Script base de arranque. El token __MENSAJE__ se reemplaza por el texto exacto
# de cada servicio. Escribe el HTML y lo sirve como un servicio systemd robusto.
locals {
  startup_script_base = <<-EOT
    #!/bin/bash
    set -e
    mkdir -p /var/www
    cat > /var/www/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="es">
    <head><meta charset="utf-8"><title>NexaCloud</title></head>
    <body><h1>__MENSAJE__</h1></body>
    </html>
    HTML
    cat > /etc/systemd/system/webapp.service <<'UNIT'
    [Unit]
    Description=NexaCloud web
    After=network.target
    [Service]
    WorkingDirectory=/var/www
    ExecStart=/usr/bin/python3 -m http.server 80
    Restart=always
    [Install]
    WantedBy=multi-user.target
    UNIT
    systemctl daemon-reload
    systemctl enable webapp
    systemctl start webapp
  EOT
}

# ------------------------------------------------------------------------------
# SERVICIO PRINCIPAL (producción)
# ------------------------------------------------------------------------------
resource "google_compute_instance_template" "tpl_produccion" {
  name         = "${var.name_prefix}-tpl-produccion"
  machine_type = "e2-micro"
  region       = var.region

  tags = [var.backend_network_tag]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = google_compute_subnetwork.subnet.name
    # Sin access_config: las VMs no tienen IP pública (entran solo por el LB).
  }

  metadata = {
    startup-script = replace(
      local.startup_script_base,
      "__MENSAJE__",
      "Bienvenido al Servicio Principal - Versión Producción"
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "hc_produccion" {
  name = "${var.name_prefix}-hc-produccion"

  http_health_check {
    port = var.backend_port
  }
}

resource "google_compute_region_instance_group_manager" "mig_produccion" {
  name               = "${var.name_prefix}-mig-produccion"
  region             = var.region
  base_instance_name = "${var.name_prefix}-prod"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.tpl_produccion.self_link
  }

  named_port {
    name = "http"
    port = var.backend_port
  }
}

# ------------------------------------------------------------------------------
# SERVICIO DE CONTINGENCIA (mantenimiento)
# ------------------------------------------------------------------------------
resource "google_compute_instance_template" "tpl_contingencia" {
  name         = "${var.name_prefix}-tpl-contingencia"
  machine_type = "e2-micro"
  region       = var.region

  tags = [var.backend_network_tag]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = google_compute_subnetwork.subnet.name
  }

  metadata = {
    startup-script = replace(
      local.startup_script_base,
      "__MENSAJE__",
      "Error 503 - Sitio en Mantenimiento Programado"
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "hc_contingencia" {
  name = "${var.name_prefix}-hc-contingencia"

  http_health_check {
    port = var.backend_port
  }
}

resource "google_compute_region_instance_group_manager" "mig_contingencia" {
  name               = "${var.name_prefix}-mig-contingencia"
  region             = var.region
  base_instance_name = "${var.name_prefix}-cont"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.tpl_contingencia.self_link
  }

  named_port {
    name = "http"
    port = var.backend_port
  }
}
