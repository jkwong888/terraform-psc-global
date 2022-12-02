/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "billing_account_id" {
  default = ""
}

variable "organization_id" {
  default = "614120287242" // jkwng.altostrat.com
}

variable "parent_folder_id" {
  default = "297737034934" // dev
}

variable "service_project_id" {
  description = "The ID of the service project which hosts the project resources e.g. dev-55427"
}

variable "registry_project_id" {
}

variable "service_project_apis_to_enable" {
  type = list(string)
  default = [
    "compute.googleapis.com",
  ]
}

variable "region" {
  description = "The region of the application e.g. us-central1"
}

variable "proxy_subnet_cidr" {
  description = "The CIDR of the psc_nat subnet e.g. 10.2.0.0/24"
}

variable "producer_subnet_cidr" {
  description = "The CIDR of the application, e.g. 10.0.0.0/24"
}

variable "dns_project_id" {
  description = "project id where cloud dns zone is hosted for cert"
}

variable "dns_zone_name" {
  description = "name of the Cloud DNS zone (public) used for dns validation of issued certificates"
}

variable "dns_name" {
  description = "hostname of the service - used to sign cert"
}

variable "acme_email" {}
variable "acme_eab_kid" {
}

variable "acme_eab_hmac_key" {
}

