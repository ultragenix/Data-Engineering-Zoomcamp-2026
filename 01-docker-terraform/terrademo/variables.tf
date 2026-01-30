variable "credentials" {
  description = "My credentials"
  default = "./keys/my-CREDENTIALS.json"
}

variable "project"{
    description = "Project Name"
    default = "cohesive-folio-485508-e4"
}

variable "region"{
    description = "Project Region"
    default = "us-central1"
}

variable "location"{
    description = "Project Location"
    default = "US"
}


variable "gcs_bucket_name"{
    description = "My Storage Bucket Name"
    default = "cohesive-folio-485508-e4-terra-bucket"
}

variable "bd_dataset_name"{
    description = "My BigQuery Dataset Name"
    default = "example_demo_dataset"
}

variable "bd_dataset_description"{
    description = "My BigQuery Dataset description"
    default = "This is a demo dataset created with terraform"
}

variable "gcs_storage_class" {
    description = "Bucket Storage Class"
    default = "STANDARD"
  
}