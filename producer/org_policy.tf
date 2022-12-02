resource "google_project_organization_policy" "shielded_vm_disable_producer" {
  project    = google_project.service_project_producer.project_id
  constraint = "constraints/compute.requireShieldedVm"

  boolean_policy {
    enforced = false 
  }
}

resource "google_project_organization_policy" "oslogin_disable" {
  project    = google_project.service_project_producer.project_id
  constraint = "constraints/compute.requireOsLogin"

  boolean_policy {
    enforced = false 
  }
}

