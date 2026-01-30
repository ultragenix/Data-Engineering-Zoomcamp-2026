

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

# add path for google credentials
# export GOOGLE_CREDENTIALS='/home/kalou/WorkSpace/Data-Engineering-Zoomcamp-2026/01-docker-terraform/terrademo/keys/my-CREDENTIALS.json'

provider "google" {
  credentials = file(var.credentials)
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "demo-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "example_demo_dataset" {
  dataset_id  = var.bd_dataset_name
  location = var.location
  description = var.bd_dataset_description
}