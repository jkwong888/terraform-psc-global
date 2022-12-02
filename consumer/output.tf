output "consumer_project_id" {
    value = google_project.service_project_consumer.project_id
}

output "consumer_vpc_name" {
    value = google_compute_network.consumer_vpc.name
}

output "consumer_ilb_ip_address" {
    value = google_compute_address.psc_ip_address.address
}