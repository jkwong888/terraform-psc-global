
data "google_folder" "parent_folder" {
    folder = var.parent_folder_id
}

data "google_billing_account" "acct" {
    billing_account = var.billing_account_id
}

resource "google_project" "service_project_consumer" {
    name                = "${var.service_project_id}"
    project_id          = "${var.service_project_id}"
    folder_id           = data.google_folder.parent_folder.id
    billing_account     = data.google_billing_account.acct.billing_account
    auto_create_network =  false
    skip_delete = false
}

resource "google_project_service" "service_project_api_consumer" {
  count                      = length(var.service_project_apis_to_enable)
  project                    = google_project.service_project_consumer.id
  service                    = element(var.service_project_apis_to_enable, count.index)
  disable_on_destroy         = false
  disable_dependent_services = false
}