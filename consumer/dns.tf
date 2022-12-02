locals {
  dns_domain_split = split(".", var.dns_name)
  dns_domain = join(".", slice(local.dns_domain_split, 1, length(local.dns_domain_split)))
}

resource "google_dns_managed_zone" "private_zone" {
  depends_on = [
    google_project_service.service_project_api_consumer,
  ]

  project       = google_project.service_project_consumer.project_id
  name          = replace(local.dns_domain, ".", "-")
  dns_name      = "${local.dns_domain}."
  description   = "PSC private zone"

  visibility = "private"

  private_visibility_config {
    networks {
        network_url = google_compute_network.consumer_vpc.id
    }
  }
}


resource "google_dns_record_set" "psc_dns" {
  project   = google_project.service_project_consumer.project_id

  name = "${var.dns_name}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private_zone.name

  rrdatas = [
    google_compute_address.psc_ip_address.address
  ]
}