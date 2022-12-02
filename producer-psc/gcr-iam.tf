data "google_project" "registry_project" {
    project_id = var.registry_project_id
}

resource "google_storage_bucket_iam_member" "proxy_registry_bucket" {

    bucket = format("artifacts.%s.appspot.com", data.google_project.registry_project.project_id)
    role = "roles/storage.objectViewer"
    member = format("serviceAccount:%s", google_service_account.helloweb_proxy.email)
}