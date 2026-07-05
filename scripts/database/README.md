# SQL Utilities Toolkit

Welcome to the **SQL Utilities Toolkit**. This repository contains a collection of lightweight, containerized Bash scripts designed to streamline database management, schema inspection, test data generation, and migration verification.

By leveraging ephemeral Docker containers with host networking, these utilities eliminate the need to install local database clients (like `psql`, `mysqldump`, or Oracle clients) while ensuring full compatibility with your local, cloud, or VPN-isolated databases.

---

## 1. Database Schema Extractor (`db-schema-extractor.sh`)

This utility exports database structures and metadata directly to a standard output file without touching or cloning actual table records. It is ideal for rapid schema inspections, version tracking, and documentation.

### Key Features
* **Multi-Engine Support**: Seamlessly works with **MySQL/MariaDB**, **PostgreSQL**, **Oracle DB**, and **MongoDB**.
* **Smart Arguments**: Uses clean, named flags (`--type`, `--host`, etc.) to maximize readability and reduce syntax errors.
* **Structure Only**: Securely extracts DDL, indexes, and collection definitions without querying or exposing sensitive data records.

### Usage Guide

#### Command Options
* `--type` : Database engine (`mysql`, `postgres`, `oracle`, or `mongo`)
* `--host` : Target server hostname, DNS, or `localhost`
* `--port` : Database network port
* `--user` : Username credential
* `--pass` : Password credential
* `--name` : Target database name (Use SID/Service Name for Oracle)

#### Concrete Examples

* **Case 1: Oracle Database (Remote or Local)**
  ```bash
  ./db-schema-extractor.sh \
    --type oracle \
    --host oracle-dev.company.internal \
    --port 1521 \
    --user system \
    --pass MySecureOraclePass \
    --name ORCL
  ```

* **Case 2: MongoDB (Extracts Collection & Indexes definitions)**
  ```bash
  ./db-schema-extractor.sh \
    --type mongo \
    --host localhost \
    --port 27017 \
    --user admin \
    --pass secretMongoPass \
    --name smartsupply
  ```

### Output Files Location
All extracted schemas are saved safely within the `results/` directory:
* **Relational (MySQL, Postgres, Oracle)**: `results/<db_name>_schema.sql`
* **NoSQL (MongoDB)**: `results/<db_name>_mongo_schema.json`

---

## 2. Database Rollback Checker (`db-rollback-checker.sh`)

This utility provides automated validation for database schemas and rollback procedures. It safely executes your sequential schema alterations within an isolated, short-lived PostgreSQL container and evaluates whether your rollback scripts can perfectly restore the database to its baseline state.

### Key Features
* **Isolated Validation**: Automatically spins up a temporary PostgreSQL Docker container to execute migrations, ensuring no side effects on your shared development databases.
* **Sequential Migration Application**: Reads and orders all forward SQL migration scripts alphabetically from a given directory to reproduce a deterministic target database state.
* **Integrity Auditing**: Applies the targeted backward rollback script and queries the system catalogs to ensure structural changes are completely reverted.
* **Orphan Detection**: Fails explicitly with an exit code 1 if any orphaned tables or objects remain in the schema after the rollback operation has been executed.

### Usage Guide

#### Command Options
* `--migration-dir` : Path to the directory containing baseline/forward SQL files (Required)
* `--rollback-file` : Path to the specific SQL rollback file to test (Optional)
* `--schema`         : Target database schema to use or create (Default: `public`)
* `--port`           : Local port to bind the temporary container (Default: `5543`)
* `--user`           : Temporary database username (Default: `postgres`)
* `--pass`           : Temporary database password (Default: `temp_secret_password_123`)
* `--name`           : Temporary database name (Default: `validator_db`)

#### Concrete Examples

* **Case 1: Validate Forward Migrations Sequence Only**
  ```bash
  ./db-rollback-checker.sh \
    --migration-dir ./migrations/v1.2.0
  ```

* **Case 2: Complete Backward Compatibility and Reversion Test**
  ```bash
  ./db-rollback-checker.sh \
    --migration-dir ./migrations/v1.2.0 \
    --rollback-file ./migrations/v1.2.0/rollback_v1.2.0.sql \
    --schema core_service
  ```

---

## 3. Database Migration Checksum Validator (`db-migration-checksum-checker.sh`)

This utility cross-references local schema definition scripts against live target environments to find discrepancies or illegal structural modifications within previously applied records. It helps maintain absolute deployment synchronicity across continuous delivery environments.

### Key Features
* **Dual Engine Integration**: Audits deployment metadata maps configured via either **Flyway** (`flyway_schema_history`) or **Liquibase** (`databasechangelog`).
* **Non-Invasive Introspection**: Validates parity tables over standard Dockerized network calls without pushing new files or staging dynamic alterations onto remote endpoints.
* **Audit Failure Flags**: Immediately appends discrepancies onto custom trace tables and returns exit code 1 if an artifact has been altered post-deployment.

### Usage Guide

#### Command Options
* `--migration-dir` : Directory containing your local SQL migration files (Required)
* `--tool`          : Migration framework type (`flyway` or `liquibase`) (Default: `flyway`)
* `--host`          : Target remote database host address (Default: `localhost`)
* `--port`          : Target remote database port (Default: `5432`)
* `--user`          : Database username (Default: `postgres`)
* `--pass`          : Database password (Default: `changeme`)
* `--name`          : Database name (Default: `smartsupply`)
* `--schema`        : Database schema name (Default: `public`)

#### Concrete Examples

* **Case 1: Validate Flyway Checklist Parity**
  ```bash
  ./db-migration-checksum-checker.sh \
    --migration-dir ./db/migrations \
    --tool flyway \
    --host pg-prod-replica.company.internal \
    --name production_db
  ```

* **Case 2: Validate Liquibase Registry Logs**
  ```bash
  ./db-migration-checksum-checker.sh \
    --migration-dir ./db/changelogs \
    --tool liquibase \
    --host localhost \
    --port 5432 \
    --name dev_workspace_db \
    --schema inventory
  ```

---

## 4. PostgreSQL Random Data Generator (`pg-data-generator.sh`)

This utility reads a live PostgreSQL schema and automatically crafts a ready-to-run `INSERT` SQL script filled with type-compliant mock data. It intelligently maps relationships so you can populate blank environments in seconds.

### Key Features
* **Dependency-Aware Ordering**: Recursively resolves foreign key constraints so parent rows are always generated and inserted before their dependent children (built-in cycle detection included).
* **Type-Correct Values**: Generates values carefully tailored to each column's distinct data type — including UUID, integer, numeric, float, boolean, date/time, `JSON`/`JSONB`, and text strings.
* **Constraint Compliance**:
    * Honours `VARCHAR`/`CHAR` length limits, including tracing the narrowest limit across the entire foreign key graph.
    * Extracts `CHECK (... = ANY (ARRAY[...]))` enumerations to guarantee only allowed values are emitted.
* **Referential Integrity**: Every foreign key column is generated as a dynamic sub-query targeting a randomly selected, valid row from the parent table.
* **Safe Bulk Inserts**: The `--rows` flag dictates how many rows are built per table. Statements utilize `ON CONFLICT DO NOTHING` so unique or composite key collisions never abort your transaction.
* **Views Excluded**: Only `BASE TABLE` objects are populated; views and their associated triggers are safely bypassed.
* **Migration Tables Ignored**: Automatically skips common schema-versioning metadata tables from **Flyway** (`flyway_schema_history`, `schema_version`) and **Liquibase** (`databasechangelog`, `databasechangeloglock`).

### Usage Guide

#### Command Options
* `--host` : Target server hostname, DNS, or `localhost`
* `--port` : PostgreSQL network port
* `--user` : Username credential
* `--pass` : Password credential
* `--name` : Target database name
* `--schema` : Target schema name (default: `public`)
* `--rows` : Number of rows to generate per table (default: `1`)

#### Concrete Examples

* **Case 1: Single row per table (default)**
  ```bash
  ./pg-data-generator.sh \
    --host localhost \
    --port 5432 \
    --user postgres \
    --pass MySecurePass \
    --name smartsupply \
    --schema smart_supply
  ```

* **Case 2: Bulk generation (100 rows per table)**
  ```bash
  ./pg-data-generator.sh \
    --host localhost \
    --port 5432 \
    --user postgres \
    --pass MySecurePass \
    --name smartsupply \
    --schema smart_supply \
    --rows 100
  ```

### Output & Execution
The generated mock data script is compiled directly into the `results/` directory:
* `results/<db_name>_random_data.sql`

The script is entirely wrapped in a single transaction block (`BEGIN; ... COMMIT;`) and configured with `\set ON_ERROR_STOP on`. Execute it against your target database like so:
```bash
psql -h localhost -p 5432 -U postgres -d smartsupply \
  -f results/smartsupply_random_data.sql
```

### How It Works Behind the Scenes
1. **Metadata Extraction**: The script runs three catalog queries against PostgreSQL to gather columns (with type and length limits), foreign key mappings, and explicit `CHECK` constraints.
2. **Resolution & Generation**: An internal, inline Node.js engine evaluates the dependency graph, computes structural column boundaries, parses valid enum values, and walks the tables to generate valid, type-correct `INSERT` scripts.
3. **Cleanup**: Temporary metadata scratchpads are wiped clean, leaving behind only your final standalone SQL script.

---

## Global Requirements & Notes

### System Requirements
To run these utilities smoothly, ensure your host environment has:
* **Docker** (The scripts dynamically spin up short-lived database client containers using `--network host`).
* **Node.js** (Required specifically by the `pg-data-generator.sh` compilation engine).
* Appropriate network routing/access permissions to target database instances.

> ### 💡 Important Usage Notes
> * **Semantic Meaning**: Generated mock data is strictly randomized and **not semantically realistic** (e.g., names and addresses will be random characters). It only guarantees strict type, length, and constraint compliance.
> * **Identity/Serial Keys**: Foreign keys referencing auto-generated identity columns are satisfied at execution runtime via `SELECT ... ORDER BY random() LIMIT 1` sub-queries.
> * **Composite Rows Count**: Due to `ON CONFLICT DO NOTHING` protections, the final count of successfully persisted rows in complex junction/bridge tables may be slightly lower than your specified `--rows` target. This is normal and prevents transaction failures.