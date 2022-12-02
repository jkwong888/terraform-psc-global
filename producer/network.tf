resource "google_compute_network" "producer_vpc" {
  project = google_project.service_project_producer.project_id
  name = "psc-producer-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "producer_subnet" {
  project       = google_project.service_project_producer.project_id
  name          = "helloweb"

  ip_cidr_range = var.producer_subnet_cidr
  region        = var.region
  network       = google_compute_network.producer_vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "producer_proxy_subnet" {
  name          = "proxy-only-subnet"
  region        = var.region
  project       = google_project.service_project_producer.project_id

  network       = google_compute_network.producer_vpc.id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  ip_cidr_range = var.proxy_subnet_cidr
  role          = "ACTIVE"
}

resource "google_compute_firewall" "allow_iap_ssh_producer" {
  project       = google_project.service_project_producer.project_id
  name          = "allow-iap-ssh"
  network       = google_compute_network.producer_vpc.name

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_healthcheck_producer" {
  project       = google_project.service_project_producer.project_id
  name          = "allow-healthchecks-l7-xlb"
  network       = google_compute_network.producer_vpc.name

  allow {
    protocol  = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16", 
    "130.211.0.0/22",
  ]
}

resource "google_compute_firewall" "allow_healthcheck_producer_nlb" {
  project       = google_project.service_project_producer.project_id
  name          = "allow-healthchecks-nlb"
  network       = google_compute_network.producer_vpc.name

  allow {
    protocol  = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16", 
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]
}

resource "google_compute_firewall" "allow_internal_producer" {
  project       = google_project.service_project_producer.project_id
  name          = "allow-internal"
  network       = google_compute_network.producer_vpc.name

  allow {
    protocol  = "all"
  }

  source_ranges = [google_compute_subnetwork.producer_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "allow_proxy_producer_ingress" {
  project       = google_project.service_project_producer.project_id
  name          = "allow-internal-proxy-ingress"
  network       = google_compute_network.producer_vpc.name

  allow {
    protocol  = "all"
  }

  source_ranges = [google_compute_subnetwork.producer_proxy_subnet.ip_cidr_range]
}