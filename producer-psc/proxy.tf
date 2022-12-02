data "google_compute_zones" "proxy_zones" {
  for_each  = toset(var.psc_proxy_subnets.*.region)
  project   = data.google_project.service_project_producer.project_id
  region    = each.key
}

resource "google_service_account" "helloweb_proxy" {
  project = data.google_project.service_project_producer.project_id
  account_id = "helloweb-proxy"
}

locals {
  proxy_iam_roles = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer",
      "roles/stackdriver.resourceMetadata.writer",
      "roles/storage.objectViewer"
  ]
}

resource "google_project_iam_member" "proxy_sa_roles" {
  count     = length(local.proxy_iam_roles)

  project   = data.google_project.service_project_producer.project_id
  role      = element(local.proxy_iam_roles, count.index)
  member    = format("serviceAccount:%s", google_service_account.helloweb_proxy.email)
}

data "google_compute_image" "cos" {
  family = "cos-stable"
  project = "cos-cloud"
}

module "proxy-container" {
  source = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image="gcr.io/jkwng-images/envoy-tcp-proxy:v1.24.0"
    env = [
      {
        name = "LISTEN_PORT"
        value = "443"
      },
      {
        name = "HEALTH_PORT"
        value = "15021"
      },
      {
        name = "DEST_ADDR"
        value = var.producer_ip_address
      },
      {
        name = "DEST_PORT"
        value = "443"
      },
      {
        name = "ENVOY_UID"
        value = "0"
      },
    ]

    # Declare volumes to be mounted.
    # This is similar to how docker volumes are declared.
    volumeMounts = []
  }

  # Declare the Volumes which will be used for mounting.
  volumes = []

  restart_policy = "Always"
}

resource "google_compute_instance_template" "envoy" {
  for_each       = toset(var.psc_proxy_subnets.*.region)
  project        = data.google_project.service_project_producer.project_id
  name_prefix    = "envoy-${each.key}-"
  machine_type   = "e2-medium"
  can_ip_forward = false
  tags           = ["helloweb-proxy"]

  disk {
    source_image = data.google_compute_image.cos.id
  }

  network_interface {
    network = data.google_compute_network.producer_vpc.self_link
    subnetwork = google_compute_subnetwork.proxy_subnet[each.key].self_link
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  metadata = {
    google-logging-enabled    = true
    google-monitoring-enabled = true

    "${module.proxy-container.metadata_key}" = module.proxy-container.metadata_value
  }

  service_account {
    email  = google_service_account.helloweb_proxy.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_region_instance_group_manager" "helloweb_proxy" {
  for_each            = toset(var.psc_proxy_subnets.*.region)
  project             = data.google_project.service_project_producer.project_id
  name                = "helloweb-proxy-mig-${each.key}"
  base_instance_name  = "proxy"
  version {
    instance_template = google_compute_instance_template.envoy[each.key].id
  }
  distribution_policy_zones =  data.google_compute_zones.proxy_zones[each.key].names
  region = each.key

  named_port {
    name = "https"
    port = 443
  }
  
  update_policy{
    type = "PROACTIVE"
    minimal_action = "REPLACE"
    max_surge_fixed = length(data.google_compute_zones.proxy_zones[each.key].names)
  }

  auto_healing_policies {
    health_check = google_compute_health_check.proxy_healthcheck.id
    initial_delay_sec = 300
  }

  target_size = 1

}

resource "google_compute_health_check" "proxy_healthcheck" {
  project             = data.google_project.service_project_producer.project_id
  name                = "proxy-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/health"
    port         = "15021"
  }
}

# create one forwarding rule per consumer region
resource "google_compute_forwarding_rule" "proxy_l4_ilb" {
  for_each              = toset(var.psc_proxy_subnets.*.region)
  project               = data.google_project.service_project_producer.project_id
  name                  = "helloweb-ilb-${each.key}"
  region                = each.key
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  allow_global_access   = false
  backend_service       = google_compute_region_backend_service.proxy_service_backend[each.key].id
  network               = data.google_compute_network.producer_vpc.name
  subnetwork            = google_compute_subnetwork.proxy_subnet[each.key].name
  network_tier          = "PREMIUM"
}

resource "google_compute_region_backend_service" "proxy_service_backend" {
  for_each     = toset(var.psc_proxy_subnets.*.region)
  project      = data.google_project.service_project_producer.project_id

  name   = "proxy-backend-service-${each.key}"
  region = each.key

  protocol = "TCP"
  load_balancing_scheme = "INTERNAL"

  health_checks = [google_compute_health_check.proxy_healthcheck.id]
  connection_draining_timeout_sec = 300

  backend {
    balancing_mode = "CONNECTION"
    group = google_compute_region_instance_group_manager.helloweb_proxy[each.key].instance_group
  }
}


/*
resource "google_compute_network_endpoint_group" "helloweb_neg" {
  project      = google_project.service_project_producer.project_id
  name         = "helloweb-neg-${random_id.random_suffix.hex}"
  network      = google_compute_network.producer_vpc.id
  subnetwork   = google_compute_subnetwork.producer_subnet[0].id
  zone         = google_compute_instance.helloweb.zone
  network_endpoint_type = "GCE_VM_IP"
}
*/