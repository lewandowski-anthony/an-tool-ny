# Modular Database Sandbox Environments via Docker Compose

This repository offers an organized collection of isolated Docker Compose configurations to deploy major relational and non-relational database management systems (DBMS). Each stack runs independently on a custom bridge network, ensuring a safe local environment for development, integration testing, or database migration experiments.

---

## 📋 Quick Reference Table

| Database Engine | Compose File | Host Port | Internal Port | Environment Variables Profile |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** (v15.8) | `postgres-compose.yaml` | `15435` | `5432` | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` |
| **MySQL** (v8.4) | `mysql-compose.yaml` | `15436` | `3306` | `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER` |
| **MongoDB** (v7.0) | `mongo-compose.yaml` | `15437` | `27017` | `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD` |
| **MS SQL Server** (2022) | `sqlserver-compose.yaml` | `15439` | `1433` | `ACCEPT_EULA`, `MSSQL_SA_PASSWORD` |
| **MariaDB** (v11.4) | `mariadb-compose.yaml` | `15440` | `3306` | `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER` |
| **Oracle Database** (XE 21) | `oracle-compose.yaml` | `15441` | `1521` | `ORACLE_PASSWORD`, `ORACLE_USER`, `ORACLE_APP_PASSWORD` |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have Docker and Docker Compose installed on your host system:

* [Get Docker](https://docs.docker.com/get-docker/)
* [Install Docker Compose](https://docs.docker.com/compose/install/)

### Environment Configuration

Every compose file uses fallback defaults to make startup friction-free. However, it is highly recommended to control your secrets securely. You can create a local `.env` file in the root directory where you run these commands to override credentials safely:

```bash
# Example .env configuration
POSTGRES_PASSWORD=my_secure_pg_pass
MYSQL_ROOT_PASSWORD=my_secure_mysql_root
MSSQL_SA_PASSWORD=Strong_Password_123!
```

---

## 💻 Deployment & Execution Instructions

Since each database has its own isolated configuration file, pass the relevant filename explicitly using the `-f` flag.

### 1. Launching a Database Engine

Run your database container in detached (background) mode:

```bash
# Spin up PostgreSQL
docker compose -f postgres-compose.yaml up -d

# Spin up MongoDB
docker compose -f mongo-compose.yaml up -d
```

### 2. Connecting to the Database via Command Line

Once a container is online, you can drop into its native client shell directly without installing database tools on your host machine.

#### Connect to PostgreSQL
```bash
docker exec -it myapp_postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-myapp_db}
```

#### Connect to MySQL
```bash
docker exec -it myapp_mysql mysql -u root -p
```

#### Connect to MongoDB
```bash
docker exec -it myapp_mongodb mongosh -u ${MONGO_ROOT_USER:-admin} -p
```

---

## 🛠️ Infrastructure Lifecycle Management

### Inspect Active Database Containers

To monitor which server engines are running and trace their active host port mapping:

```bash
docker ps
```

### Gracefully Stopping a Database Engine

To pause your database service without risking database state corruption:

```bash
docker compose -f <database-filename>-compose.yaml stop
```
*This pauses the engines but safely preserves all databases, tables, and records within dedicated Docker volumes.*

### Removing Stacks and Cleaning Up

To shut down containers and tear down the virtual bridge networks:

```bash
docker compose -f <database-filename>-compose.yaml down
```

To purge the entire stack along with its persistent transactional logs and data volumes, pass the `-v` flag:

```bash
docker compose -f <database-filename>-compose.yaml down -v
```
> **Warning:** This will permanently delete all databases and data stored inside that specific container engine's environment.

---

## 💡 Troubleshooting & Production Guidelines

* **Microsoft SQL Server Password Complexity:** If the MS SQL server container repeatedly fails to start or crashes immediately, inspect your logs with `docker logs myapp_mssql`. The image enforces strict default Windows/SQL Server password complexity requirements. Ensure your `MSSQL_SA_PASSWORD` contains upper and lowercase characters, digits, or symbols.
* **Oracle XE Initialization:** Oracle Database containers generally take longer to start than lightweight engines like Postgres or MariaDB due to initialization routines during its first boot. Monitor readiness with `docker logs -f myapp_oracle`.
* **Port Customization:** If you run multiple stacks simultaneously (e.g., MySQL and MariaDB), notice that they are assigned distinct host port mappings (`15436` vs `15440`) to avoid resource conflicts on your machine, even though both internal containers map to database port `3306`.
```