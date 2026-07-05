terraform {
  required_version = ">= 1.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# -------------------------------------------------------------------
# 1. Local Kubernetes Cluster Creation
# -------------------------------------------------------------------
resource "kind_cluster" "anthony_cluster" {
  name            = "anthony-cluster"
  kubeconfig_path = expanduser("~/.kube/config")
  wait_for_ready  = true
}

# -------------------------------------------------------------------
# 2. Providers configuration
# -------------------------------------------------------------------
provider "kubernetes" {
  config_path    = kind_cluster.anthony_cluster.kubeconfig_path
  config_context = "kind-anthony-cluster"
}

provider "google" {
  project = "mrp-exchange-04l8"
  region  = "europe-west4"
}

# -------------------------------------------------------------------
# 3. Preprod context : anthony-eu-pp
# -------------------------------------------------------------------

resource "kubernetes_namespace" "pp_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pp"
      env     = "preprod"
    }
  }
}

resource "kubernetes_namespace" "pp_anthony_qual" {
  metadata {
    name = "anthony-qual"
    labels = {
      context = "anthony-eu-pp"
      env     = "qual"
    }
  }
}

# Preprod DB Instance (Cloud SQL PostgreSQL)
resource "google_sql_database_instance" "db_instance_pp" {
  name             = "instance-anthony-pp"
  database_version = "POSTGRES_16"
  region           = "europe-west4"
  settings {
    tier = "db-f1-micro" # Instance partagée économique pour le dev/test
  }
  deletion_protection = false
}

resource "google_sql_database" "db_pp_anthony" {
  name     = "db_anthony_pp"
  instance = google_sql_database_instance.db_instance_pp.name
}

# Qual DB Instance (Cloud SQL PostgreSQL)
resource "google_sql_database_instance" "db_instance_qual" {
  name             = "instance-anthony-qual"
  database_version = "POSTGRES_16"
  region           = "europe-west4"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false
}

resource "google_sql_database" "db_pp_anthony_qual" {
  name     = "db_anthony_qual"
  instance = google_sql_database_instance.db_instance_qual.name
}

# -------------------------------------------------------------------
# 4. Production context : anthony-eu-pr
# -------------------------------------------------------------------

resource "kubernetes_namespace" "pr_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pr"
      env     = "prod"
    }
  }
}

# Production DB Instance
resource "google_sql_database_instance" "db_instance_pr" {
  name             = "instance-anthony-pr"
  database_version = "POSTGRES_16"
  region           = "europe-west4"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false
}

resource "google_sql_database" "db_pr_anthony" {
  name     = "db_anthony_pr"
  instance = google_sql_database_instance.db_instance_pr.name
}