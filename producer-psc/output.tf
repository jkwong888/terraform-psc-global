output "service_attachment_map" {
  value         = zipmap(var.psc_proxy_subnets.*.region,
                         values(google_compute_service_attachment.helloweb_ilb_service_attachment).*.self_link)
}