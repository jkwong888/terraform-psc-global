data "google_project" "dns_project" {
  project_id = var.dns_project_id
}

data "google_compute_region_instance_group" "helloweb" {
  project   = data.google_project.service_project_producer.project_id
  self_link = var.instance_group_id
}

resource "google_compute_global_address" "helloweb_ip_address" {
  project   = data.google_project.service_project_producer.project_id
  name      = "helloweb-glb-${random_id.random_suffix.hex}"
}

resource "google_dns_record_set" "helloweb_a" {
  project   = data.google_project.dns_project.project_id

  name = "helloweb-${random_id.random_suffix.hex}.gcp.jkwong.info."
  type = "A"
  ttl  = 5

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name

  rrdatas = [
    google_compute_global_address.helloweb_ip_address.address
  ]
}

resource "google_compute_backend_service" "helloweb_service_backend" {
  project      = data.google_project.service_project_producer.project_id

  name   = "helloweb-backend-service-${random_id.random_suffix.hex}"

  protocol = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [google_compute_health_check.helloweb_healthcheck.id]
  connection_draining_timeout_sec = 300

  backend {
    balancing_mode = "UTILIZATION"
    group = data.google_compute_region_instance_group.helloweb.id
    capacity_scaler = 0.8
  }
}

resource "google_compute_health_check" "helloweb_healthcheck" {
  project             = data.google_project.service_project_producer.project_id
  name                = "helloweb-health-check-${random_id.random_suffix.hex}"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}



resource "google_compute_target_https_proxy" "helloweb" {
  project  = data.google_project.service_project_producer.project_id
  name     = "helloweb-https-proxy-${random_id.random_suffix.hex}"
  url_map  = google_compute_url_map.helloweb.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.helloweb.id}"
}

resource "google_certificate_manager_certificate_map" "helloweb" {
  project         = data.google_project.service_project_producer.project_id
  name        = "helloweb-cert-map-${random_id.random_suffix.hex}"
}

resource "google_certificate_manager_certificate_map_entry" "helloweb-default" {
  project         = data.google_project.service_project_producer.project_id
  name        = "helloweb-cert-map-default-${random_id.random_suffix.hex}"

  map = google_certificate_manager_certificate_map.helloweb.name 
  certificates = [google_certificate_manager_certificate.cert.id]

  matcher = "PRIMARY"
}

# URL map
resource "google_compute_url_map" "helloweb" {
  project         = data.google_project.service_project_producer.project_id
  name            = "helloweb-url-map-${random_id.random_suffix.hex}"
  provider        = google-beta
  default_service = google_compute_backend_service.helloweb_service_backend.id
}

resource "google_compute_global_forwarding_rule" "helloweb_l7_glb" {
  project               = data.google_project.service_project_producer.project_id
  name                  = "helloweb-l7-ilb-${random_id.random_suffix.hex}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = 443
  target                = google_compute_target_https_proxy.helloweb.id
  ip_address            = google_compute_global_address.helloweb_ip_address.self_link
}

# cert
data "google_dns_managed_zone" "env_dns_zone" {
  provider  = google-beta
  name      = "gcp-jkwong-info"
  project   = data.google_project.dns_project.project_id
}

resource "google_certificate_manager_certificate" "cert" {
  depends_on = [
    google_project_service.certificatemanager_project_api,
  ]

  project   = data.google_project.service_project_producer.project_id
  name = "helloweb-${random_id.random_suffix.hex}"
  scope = "DEFAULT"
  managed {
    domains = [
      //"helloweb-${random_id.random_suffix.hex}.gcp.jkwong.info",
      "*.gcp.jkwong.info",
    ]

    dns_authorizations = [
      //google_certificate_manager_dns_authorization.helloweb.id,
      google_certificate_manager_dns_authorization.wildcard.id,
    ]
  }
}

resource "google_certificate_manager_dns_authorization" "helloweb" {
  project   = data.google_project.service_project_producer.project_id
  name        = "helloweb-${random_id.random_suffix.hex}-dns-auth"
  domain      = "helloweb-${random_id.random_suffix.hex}.gcp.jkwong.info"
}

resource "google_certificate_manager_dns_authorization" "wildcard" {
  project   = data.google_project.service_project_producer.project_id
  name        = "wildcard-dns-auth-${random_id.random_suffix.hex}"
  domain      = "gcp.jkwong.info"
}

resource "google_dns_record_set" "helloweb_auth" {
  depends_on = [
    google_certificate_manager_dns_authorization.helloweb,
  ]

  project   = data.google_project.dns_project.project_id

  name = google_certificate_manager_dns_authorization.helloweb.dns_resource_record.0.name
  type = google_certificate_manager_dns_authorization.helloweb.dns_resource_record.0.type
  ttl  = 5

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name

  rrdatas = [
    google_certificate_manager_dns_authorization.helloweb.dns_resource_record.0.data

  ]
}

resource "google_dns_record_set" "wildcard_auth" {
  depends_on = [
    google_certificate_manager_dns_authorization.wildcard,
  ]

  project   = data.google_project.dns_project.project_id

  name = google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.name
  type = google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.type
  ttl  = 5

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name

  rrdatas = [
    google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.data

  ]
}


/*

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "jeffrey.kwong@gmail.com"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "helloweb-${random_id.random_suffix.hex}.gcp.jkwong.info"

  dns_challenge {
    provider = "gcloud"
    config = {
      "GCE_PROJECT" = data.google_project.dns_project.project_id
    }
  }
}
*/