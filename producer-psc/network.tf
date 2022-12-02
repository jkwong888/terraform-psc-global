data "google_compute_network" "producer_vpc" {
  project       = data.google_project.service_project_producer.project_id
  name          = var.producer_vpc_name
}

resource "google_compute_subnetwork" "proxy_subnet" {
  for_each      = zipmap(var.psc_proxy_subnets.*.region, var.psc_proxy_subnets)

  project       = data.google_project.service_project_producer.project_id
  name          = "producer-proxy-${each.value.region}"

  ip_cidr_range = each.value.proxy_subnet_cidr
  region        = each.value.region
  network       = data.google_compute_network.producer_vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "psc_nat_subnet" {
  for_each      = zipmap(var.psc_proxy_subnets.*.region, var.psc_proxy_subnets)

  project       = data.google_project.service_project_producer.project_id
  name          = "producer-psc-nat-${each.value.region}"

  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = each.value.psc_nat_subnet_cidr
  region        = each.value.region
  network       = data.google_compute_network.producer_vpc.id

  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_proxy_producer_ingress" {
  project       = data.google_project.service_project_producer.project_id
  name          = "allow-envoy-to-backend"
  network       = data.google_compute_network.producer_vpc.name

  allow {
    protocol  = "all"
  }

  source_ranges = [for s in google_compute_subnetwork.psc_nat_subnet: s.ip_cidr_range]
  target_service_accounts = [var.producer_service_account]
}

resource "google_compute_firewall" "allow_psc_nat_producer_ingress" {
  project       = data.google_project.service_project_producer.project_id
  name          = "allow-psc-nat-to-envoy"
  network       = data.google_compute_network.producer_vpc.name

  allow {
    protocol  = "all"
  }

  source_ranges = [for s in google_compute_subnetwork.psc_nat_subnet: s.ip_cidr_range]
  target_service_accounts = [google_service_account.helloweb_proxy.email]
}

