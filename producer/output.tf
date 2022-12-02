output "producer_project_id" {
    value = google_project.service_project_producer.project_id
}

output "producer_vpc_name" {
    value = google_compute_network.producer_vpc.name
}

output "producer_ilb_ip_address" {
    value = google_compute_address.helloweb_ip_address.address
}

output "producer_service_account" {
    value = google_service_account.helloweb.email
}

output "producer_instance_group_id" {
    value = google_compute_region_instance_group_manager.helloweb.instance_group
}