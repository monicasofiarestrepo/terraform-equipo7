resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "${var.name_prefix}-allow-lb-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }

  # Rangos oficiales de GCP para LB y health checks
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = [var.backend_network_tag]
}

resource "google_compute_firewall" "deny_ssh_external" {
  name     = "${var.name_prefix}-deny-ssh-external"
  network  = google_compute_network.vpc.name
  priority = 1000

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
