data "google_project" "registry_project" {
    project_id = var.registry_project_id
}

resource "google_storage_bucket_iam_member" "compute_engine_default_registry_bucket" {
    depends_on = [
        google_project_service.service_project_api_producer,
    ]

    bucket = format("artifacts.%s.appspot.com", data.google_project.registry_project.project_id)
    role = "roles/storage.objectViewer"
    member = format("serviceAccount:%s", google_service_account.helloweb.email)
}