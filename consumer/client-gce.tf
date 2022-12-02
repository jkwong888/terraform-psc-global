// client VMs

data "google_compute_zones" "consumer_available" {
  count     = length(var.consumer_subnets)
  project   = google_project.service_project_consumer.project_id
  region    = var.consumer_subnets[count.index].region
}

data "google_compute_image" "debian" {
  family = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_instance" "client_consumer" {

  depends_on = [
    google_project_organization_policy.shielded_vm_disable_consumer,
  ]

  count        = length(var.consumer_subnets)
  project      = google_project.service_project_consumer.project_id
  name         = "consumer-${var.consumer_subnets[count.index].region}"
  machine_type = "e2-medium"
  zone         = data.google_compute_zones.consumer_available[count.index].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.id
    }
  }

  network_interface {
    network = google_compute_network.consumer_vpc.self_link
    subnetwork = google_compute_subnetwork.consumer_subnet[count.index].self_link
  }

  metadata = {
    google-logging-enabled    = true
    google-monitoring-enabled = true
  }
}