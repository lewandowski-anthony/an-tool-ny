resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment_name == "qual" ? "anthony-qual" : "anthony"
    labels = {
      context = var.context_name
      env     = var.environment_name
    }
  }
}

resource "aws_db_instance" "app_db" {
  allocated_storage   = 20
  db_name             = "db_anthony_${var.environment_name}"
  engine              = "postgres"
  instance_class      = var.db_instance_class
  username            = "app_${var.environment_name}_user"
  password            = "changeme123!"

  skip_final_snapshot = var.environment_name == "prod" ? false : true

  tags = {
    Context = var.context_name
    Env     = var.environment_name
  }
}