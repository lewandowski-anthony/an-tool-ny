variable "environment_name" {
  type        = string
  description = "The target environment name (e.g., preprod, qual, prod)."
}

variable "context_name" {
  type        = string
  description = "The associated kubectl context name used for labeling (e.g., anthony-eu-pp)."
}

variable "project_id" {
  type        = string
  description = "The Google Cloud Platform project ID."
  default     = "mrp-exchange-04l8"
}

variable "region" {
  type        = string
  description = "The GCP region where resources will be deployed."
  default     = "europe-west4"
}

variable "db_tier" {
  type        = string
  description = "The machine type/tier for the Cloud SQL instance."
  default     = "db-f1-micro"
}