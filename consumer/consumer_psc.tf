
resource "google_compute_address" "psc_ip_address" {
  project   = google_project.service_project_consumer.project_id
  name      = "helloweb-address"

  region        = var.consumer_subnets[0].region
  address_type  = "INTERNAL"
  subnetwork    = google_compute_subnetwork.consumer_subnet[0].id
}

resource "google_compute_forwarding_rule" "helloweb_consumer_psc_ilb" {
  project               = google_project.service_project_consumer.project_id
  name                  = "helloweb-consumer"
  region                = var.consumer_subnets[0].region
  load_balancing_scheme = ""
  target                = var.service_attachment_map[var.consumer_subnets[0].region]
  network               = google_compute_network.consumer_vpc.name
  ip_address            = google_compute_address.psc_ip_address.id
}