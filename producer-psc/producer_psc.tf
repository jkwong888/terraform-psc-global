resource "google_compute_service_attachment" "helloweb_ilb_service_attachment" {
  for_each      = toset(var.psc_proxy_subnets.*.region)
  project       = data.google_project.service_project_producer.project_id
  name          = "psc-helloweb-ilb-${each.key}"
  region        = each.key
  description   = "helloweb in ${each.key}"

  # observed -- proxy protocol = true results in 400 bad request errors
  enable_proxy_protocol    = false
  connection_preference    = "ACCEPT_AUTOMATIC"
  nat_subnets              = [google_compute_subnetwork.psc_nat_subnet[each.key].id]
  target_service           = google_compute_forwarding_rule.proxy_l4_ilb[each.key].id
}
