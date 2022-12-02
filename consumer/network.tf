resource "google_compute_network" "consumer_vpc" {
  project = google_project.service_project_consumer.project_id
  name = "psc-consumer-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "consumer_subnet" {
  count         = length(var.consumer_subnets)
  project       = google_project.service_project_consumer.project_id
  name          = "psc-consumer-${var.consumer_subnets[count.index].region}"
  ip_cidr_range = var.consumer_subnets[count.index].cidr
  region        = var.consumer_subnets[count.index].region
  network       = google_compute_network.consumer_vpc.id

  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_iap_ssh_consumer" {
  project       = google_project.service_project_consumer.project_id
  name          = "allow-iap-ssh"
  network       = google_compute_network.consumer_vpc.name

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_all_ssh_consumer" {
  project       = google_project.service_project_consumer.project_id
  name          = "allow-all-ssh"
  network       = google_compute_network.consumer_vpc.name

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal_consumer" {
  project       = google_project.service_project_consumer.project_id
  name          = "allow-internal"
  network       = google_compute_network.consumer_vpc.name

  allow {
    protocol  = "all"
  }

  source_ranges = google_compute_subnetwork.consumer_subnet.*.ip_cidr_range
}

