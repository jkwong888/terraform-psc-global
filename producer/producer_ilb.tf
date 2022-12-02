data "google_project" "dns_project" {
  project_id = var.dns_project_id
}

locals {
  app_name = split(".", var.dns_name)[0]
}

resource "google_compute_address" "helloweb_ip_address" {
  project   = google_project.service_project_producer.project_id
  name      = "${local.app_name}-address"

  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = google_compute_subnetwork.producer_subnet.id
}

resource "google_compute_region_backend_service" "helloweb_service_backend" {
  project      = google_project.service_project_producer.project_id

  name   = "${local.app_name}-backend-service"
  region = var.region

  protocol = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"

  health_checks = [google_compute_health_check.helloweb_healthcheck.id]
  connection_draining_timeout_sec = 300

  backend {
    balancing_mode = "UTILIZATION"
    group = google_compute_region_instance_group_manager.helloweb.instance_group
    capacity_scaler = 0.8
  }
}

resource "google_compute_region_ssl_certificate" "helloweb" {
  project     = google_project.service_project_producer.project_id
  region      = var.region
  name        = replace(var.dns_name, ".", "-")
  certificate = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}" 
  private_key = acme_certificate.certificate.private_key_pem
}

resource "google_compute_region_target_https_proxy" "helloweb" {
  project  = google_project.service_project_producer.project_id
  name     = "${local.app_name}-https-proxy"
  provider = google-beta
  region   = var.region
  url_map  = google_compute_region_url_map.helloweb.id
  ssl_certificates = [
    google_compute_region_ssl_certificate.helloweb.id,
  ]
}

# URL map
resource "google_compute_region_url_map" "helloweb" {
  project         = google_project.service_project_producer.project_id
  name            = "${local.app_name}-url-map"
  provider        = google-beta
  region          = var.region
  default_service = google_compute_region_backend_service.helloweb_service_backend.id
}

resource "google_compute_forwarding_rule" "helloweb_l7_ilb" {
  depends_on = [
    google_compute_subnetwork.producer_proxy_subnet,
  ]
  project               = google_project.service_project_producer.project_id
  name                  = "${local.app_name}-l7-ilb"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = 443
  allow_global_access   = true
  target                = google_compute_region_target_https_proxy.helloweb.id
  network               = google_compute_network.producer_vpc.name
  subnetwork            = google_compute_subnetwork.producer_subnet.name
  ip_address            = google_compute_address.helloweb_ip_address.self_link
  network_tier          = "PREMIUM"
}

# cert
data "google_dns_managed_zone" "env_dns_zone" {
  provider  = google-beta
  name      = var.dns_zone_name
  project   = data.google_project.dns_project.project_id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.acme_email
  external_account_binding {
    key_id = var.acme_eab_kid
    hmac_base64 = var.acme_eab_hmac_key
  }
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.dns_name

  dns_challenge {
    provider = "gcloud"
    config = {
      "GCE_PROJECT" = data.google_project.dns_project.project_id
    }
  }
}