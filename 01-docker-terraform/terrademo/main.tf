

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  # Configuration options
  project     = "cohesive-folio-485508-e4"
  region      = "us-central1"
}

