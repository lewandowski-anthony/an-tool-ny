resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment_name == "qual" ? "anthony-qual" : "anthony"
    labels = {
      context = var.context_name
      env     = var.environment_name
    }
  }
}

resource "google_sql_database_instance" "db_instance" {
  name             = "instance-anthony-${var.environment_name}"
  database_version = "POSTGRES_16"
  region           = var.region
  project          = var.project_id

  settings {
    tier = var.db_tier
  }

  deletion_protection = var.environment_name == "prod" ? true : false
}

resource "google_sql_database" "app_db" {
  name     = "db_anthony_${var.environment_name}"
  instance = google_sql_database_instance.db_instance.name
  project  = var.project_id
}