output "producer_project_id" {
    value = module.producer.producer_project_id
}

output "producer_ilb_ip_address" {
    value = module.producer.producer_ilb_ip_address
}

output "service_attachments" {
  value = module.producer_psc.service_attachment_map
}

output "consumer_project_id" {
    value = module.consumer.consumer_project_id
}

output "consumer_vpc_name" {
    value = module.consumer.consumer_vpc_name
}
output "consumer_ilb_ip_address" {
    value = module.consumer.consumer_ilb_ip_address
}
