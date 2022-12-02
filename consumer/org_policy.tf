resource "google_project_organization_policy" "shielded_vm_disable_consumer" {
  project    = google_project.service_project_consumer.project_id
  constraint = "constraints/compute.requireShieldedVm"

  boolean_policy {
    enforced = false 
  }
}