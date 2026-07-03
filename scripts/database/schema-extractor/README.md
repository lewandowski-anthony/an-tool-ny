# Database Schema Extractor (`db-schema-extractor.sh`)

This universal Bash utility automates the extraction of database models and structures into a standard file. It uses ephemeral Docker containers with host networking, meaning zero native installations on your Mac and 100% cloud/VPN compatibility.

---

## 🚀 Key Features

* **Multi-Engine Support**: Works seamlessly with **MySQL/MariaDB**, **PostgreSQL**, **Oracle DB**, and **MongoDB**.
* **Smart Arguments**: Named flags (`--type`, `--host`, etc.) prevent syntax errors and maintain command history readability.
* **Metadata & Structure Only**: Pure DDL and index extractions without touching or cloning table records.

---

## 🛠️ Usage Guide

### 1. Command Options
* `--type` : Database engine (`mysql`, `postgres`, `oracle`, or `mongo`)
* `--host` : Target server hostname, DNS, or `localhost`
* `--port` : Database network port
* `--user` : Username credential
* `--pass` : Password credential
* `--name` : Target database name (Use SID/Service Name for Oracle)

### 2. Concrete Examples

#### 🔹 Case 1: Oracle Database (Remote or Local)
```bash
./db-schema-extractor.sh \
--type oracle \
--host oracle-dev.company.internal \
--port 1521 \
--user system \
--pass MySecureOraclePass \
--name ORCL
```

#### 🔹 Case 2: MongoDB (Extracts Collection & Indexes definitions)
```bash
./db-schema-extractor.sh \
--type mongo \
--host localhost \
--port 27017 \
--user admin \
--pass secretMongoPass \
--name smartsupply
```

---

## 🔍 Output Files Location

The extracted files will be safely stored under the `results/` directory:
* **Relational (MySQL, Postgres, Oracle)**: `results/<db_name>_schema.sql`
* **NoSQL (MongoDB)**: `results/<db_name>_mongo_schema.json`