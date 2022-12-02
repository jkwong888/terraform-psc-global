data "google_project" "service_project_producer" {
    project_id          = var.producer_project_id
}

resource "random_id" "random_suffix" {
  byte_length = 2
}

resource "google_project_service" "certificatemanager_project_api" {
  project                    = data.google_project.service_project_producer.id
  service                    = "certificatemanager.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}