data "google_folder" "parent_folder" {
    folder = format("folders/%s", var.parent_folder_id)
}

resource "random_id" "random_suffix" {
  byte_length = 2
}

data "google_billing_account" "acct" {
    billing_account = var.billing_account_id
}

resource "google_folder" "psc_folder" {
  display_name = "private-service-connect-${random_id.random_suffix.hex}"
  parent = data.google_folder.parent_folder.id
}

module "producer" {
  source = "./producer"

  providers = {
    acme = acme.google-publicca
  }

  billing_account_id = var.billing_account_id
  parent_folder_id = google_folder.psc_folder.id

  service_project_id = "${var.service_project_id}-${random_id.random_suffix.hex}-producer"
  registry_project_id = var.registry_project_id
  dns_project_id = var.dns_project_id
  dns_zone_name = var.dns_zone_name
  dns_name = var.dns_name

  service_project_apis_to_enable = [
      "compute.googleapis.com",
      "certificatemanager.googleapis.com",
      "publicca.googleapis.com",
  ]

  region = var.producer_region
  proxy_subnet_cidr = var.producer_proxy_subnet_cidr
  producer_subnet_cidr = var.producer_subnet_cidr

  acme_email = var.acme_email
  acme_eab_hmac_key = var.acme_eab_hmac_key
  acme_eab_kid = var.acme_eab_kid
}

module "producer_psc" {
  source = "./producer-psc"

  registry_project_id = var.registry_project_id

  producer_project_id = module.producer.producer_project_id
  producer_vpc_name = module.producer.producer_vpc_name
  producer_ip_address = module.producer.producer_ilb_ip_address
  producer_service_account = module.producer.producer_service_account

  psc_proxy_subnets = var.producer_psc_proxy_subnets
}


module "consumer" {
  source = "./consumer"

  billing_account_id = var.billing_account_id
  parent_folder_id = google_folder.psc_folder.id

  service_project_id = "${var.service_project_id}-${random_id.random_suffix.hex}-consumer"
  registry_project_id = var.registry_project_id

  service_project_apis_to_enable = [
      "compute.googleapis.com",
      "dns.googleapis.com",
  ]


  consumer_subnets = var.consumer_subnets
  service_attachment_map = module.producer_psc.service_attachment_map

  dns_name = var.dns_name
}
