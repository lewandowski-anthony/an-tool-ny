variable "environment_name" {
  type        = string
  description = "The target environment name (e.g., preprod, qual, prod)."
}

variable "context_name" {
  type        = string
  description = "The associated kubectl context name used for tagging."
}

variable "region" {
  type        = string
  description = "The AWS region where resources will be deployed."
  default     = "eu-west-3"
}

variable "db_instance_class" {
  type        = string
  description = "The compute and memory capacity class for the RDS PostgreSQL instance."
  default     = "db.t4g.micro"
}