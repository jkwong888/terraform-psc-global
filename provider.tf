terraform {
  backend "gcs" {
    bucket  = "jkwng-altostrat-com-tf-state"
    prefix = "jkwng-psc"
  }

  required_providers {
    google = {
      version = "~> 4.44"
    }
    google-beta = {
      version = "~> 4.44"

    }
    null = {
      version = "~> 2.1"
    }
    random = {
      version = "~> 2.2"
    }
    acme = {
      source = "vancluever/acme"
      version = "2.11.1"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "google" {
#  credentials = file(local.credentials_file_path)
}

provider "google-beta" {
#  credentials = file(local.credentials_file_path)
}

provider "null" {
}

provider "random" {
}

provider "acme" {
  # Configuration options
  alias = "letsencrypt"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "acme" {
  alias = "google-publicca"
  server_url = "https://dv.acme-v02.api.pki.goog/directory"
}

provider "tls" {
  # Configuration options
}