variable "environment_name" {
  type        = string
  description = "The target environment name (e.g., preprod, qual, prod)."
}

variable "context_name" {
  type        = string
  description = "The associated kubectl context name used for labeling."
}

variable "location" {
  type        = string
  description = "The Azure region/location where the Resource Group and services will be provisioned."
  default     = "westeurope"
}

variable "sku_name" {
  type        = string
  description = "The performance SKU tier for the Azure PostgreSQL Flexible Server."
  default     = "B_Standard_B1ms"
}