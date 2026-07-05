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
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------------------------------------------------------
# 1. Local Kubernetes Cluster Creation
# -------------------------------------------------------------------
resource "kind_cluster" "anthony_cluster" {
  name           = "anthony-cluster"
  kubeconfig_path = expanduser("~/.kube/config")
  wait_for_ready = true
}

# -------------------------------------------------------------------
# 2. Providers configuration
# -------------------------------------------------------------------
provider "kubernetes" {
  config_path    = kind_cluster.anthony_cluster.kubeconfig_path
  config_context = "kind-anthony-cluster"
}

provider "aws" {
  region                      = "eu-west-3"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    rds = "http://localhost:4566"
  }
}

# -------------------------------------------------------------------
# 3. Preprod context : anthony-eu-pp
# -------------------------------------------------------------------

# Anthony namespace on Preprod
resource "kubernetes_namespace" "pp_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pp"
      env     = "preprod"
    }
  }
}

# Qual namespace on Preprod
resource "kubernetes_namespace" "pp_anthony_qual" {
  metadata {
    name = "anthony-qual"
    labels = {
      context = "anthony-eu-pp"
      env     = "qual"
    }
  }
}

# Preprod environment database (anthony)
resource "aws_db_instance" "db_pp_anthony" {
  allocated_storage   = 20
  db_name             = "db_anthony_pp"
  engine              = "postgres"
  instance_class      = "db.t4g.micro"
  username            = "app_pp_user"
  password            = "changeme123!"
  skip_final_snapshot = true
  tags = { Context = "anthony-eu-pp", Env = "preprod" }
}

# Qual environment database (anthony-qual)
resource "aws_db_instance" "db_pp_anthony_qual" {
  allocated_storage   = 20
  db_name             = "db_anthony_qual"
  engine              = "postgres"
  instance_class      = "db.t4g.micro"
  username            = "app_qual_user"
  password            = "changeme123!"
  skip_final_snapshot = true
  tags = { Context = "anthony-eu-pp", Env = "qual" }
}

# -------------------------------------------------------------------
# 4. Production context : anthony-eu-pr
# -------------------------------------------------------------------

# Anthony namespace on Production
resource "kubernetes_namespace" "pr_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pr"
      env     = "prod"
    }
  }
}

# Production database
resource "aws_db_instance" "db_pr_anthony" {
  allocated_storage   = 20
  db_name             = "db_anthony_pr"
  engine              = "postgres"
  instance_class      = "db.t4g.micro"
  username            = "app_pr_user"
  password            = "changeme123!"
  skip_final_snapshot = true
  tags = { Context = "anthony-eu-pr", Env = "prod" }
}