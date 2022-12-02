data "google_compute_zones" "producer_backend_available" {
  project   = google_project.service_project_producer.project_id
  region    = var.region
}

resource "google_service_account" "helloweb" {
  project = google_project.service_project_producer.project_id
  account_id = "helloweb"
}

data "google_compute_image" "cos" {
  family = "cos-stable"
  project = "cos-cloud"
}

module "gce-container" {
  source = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image="gcr.io/jkwng-images/helloweb:1.3.1"
    env = []

    # Declare volumes to be mounted.
    # This is similar to how docker volumes are declared.
    volumeMounts = []
  }

  # Declare the Volumes which will be used for mounting.
  volumes = []

  restart_policy = "Always"
}

resource "google_compute_instance_template" "helloweb_tmpl" {
  project      = google_project.service_project_producer.project_id
  name_prefix         = "helloweb-"
  machine_type = "e2-medium"

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = data.google_compute_image.cos.id
  }

  network_interface {
    network = google_compute_network.producer_vpc.self_link
    subnetwork = google_compute_subnetwork.producer_subnet.self_link
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.helloweb.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    google-logging-enabled    = true
    google-monitoring-enabled = true

    "${module.gce-container.metadata_key}" = module.gce-container.metadata_value
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "google_compute_region_instance_group_manager" "helloweb" {
  project             = google_project.service_project_producer.project_id
  name                = "helloweb-mig"
  base_instance_name  = "helloweb"
  version {
    instance_template = google_compute_instance_template.helloweb_tmpl.id
  }
  distribution_policy_zones =  data.google_compute_zones.producer_backend_available.names
  region = var.region

  named_port {
    name = "http"
    port = 8080
  }

  auto_healing_policies {
    health_check = google_compute_health_check.helloweb_healthcheck.id
    initial_delay_sec = 300
  }

  target_size = 1
}

resource "google_compute_health_check" "helloweb_healthcheck" {
  project             = google_project.service_project_producer.project_id
  name                = "helloweb-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "8080"
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