# Database Schema Extractor (`db-schema-extractor.sh`)

This Bash utility exports database structures to a standard output file. It uses ephemeral Docker containers with host networking, so you can inspect schemas without installing database clients locally and while still working through cloud or VPN access.

---

## Key Features

* **Multi-Engine Support**: Works with **MySQL/MariaDB**, **PostgreSQL**, **Oracle DB**, and **MongoDB**.
* **Smart Arguments**: Named flags (`--type`, `--host`, etc.) make commands easier to read and reduce syntax mistakes.
* **Metadata & Structure Only**: Extracts DDL and indexes without touching or cloning table records.

---

## Usage Guide

### 1. Command Options
* `--type` : Database engine (`mysql`, `postgres`, `oracle`, or `mongo`)
* `--host` : Target server hostname, DNS, or `localhost`
* `--port` : Database network port
* `--user` : Username credential
* `--pass` : Password credential
* `--name` : Target database name (Use SID/Service Name for Oracle)

### 2. Concrete Examples

#### Case 1: Oracle Database (Remote or Local)
```bash
./db-schema-extractor.sh \
--type oracle \
--host oracle-dev.company.internal \
--port 1521 \
--user system \
--pass MySecureOraclePass \
--name ORCL
```

#### Case 2: MongoDB (Extracts Collection & Indexes definitions)
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

## Output Files Location

The extracted files are stored under the `results/` directory:
* **Relational (MySQL, Postgres, Oracle)**: `results/<db_name>_schema.sql`
* **NoSQL (MongoDB)**: `results/<db_name>_mongo_schema.json`
