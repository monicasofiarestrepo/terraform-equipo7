resource "google_compute_global_address" "lb_ip" {
  name = "${var.name_prefix}-lb-ip"
}
