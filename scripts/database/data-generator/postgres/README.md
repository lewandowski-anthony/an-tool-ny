# PostgreSQL Random Data Generator (`pg-data-generator.sh`)

This Bash utility introspects a live PostgreSQL schema and generates a ready-to-run `INSERT` script populated with random data. It resolves foreign-key dependencies automatically and respects column types, length limits, `CHECK` enumerations, and referential integrity. It runs through an ephemeral Docker container with host networking, so no native `psql` installation is required.

---

## 🚀 Key Features

* **Dependency-Aware Ordering**: Recursively resolves foreign keys so parent rows are always inserted before their children (with cycle detection).
* **Type-Correct Values**: Generates values matching each column's data type — UUID, integer, numeric, float, boolean, date/time, `JSON`/`JSONB`, and text.
* **Constraint Compliance**:
  * Honours `VARCHAR`/`CHAR` length limits, including the narrowest limit across the whole FK graph.
  * Extracts `CHECK (... = ANY (ARRAY[...]))` enumerations and only emits allowed values.
* **Referential Integrity**: Every foreign key is emitted as a sub-query that targets a randomly selected, actually-present parent row.
* **Safe Bulk Inserts**: `--rows` generates multiple rows per table, and every statement uses `ON CONFLICT DO NOTHING` so unique/composite-key collisions never abort the transaction.
* **Views Excluded**: Only `BASE TABLE` objects are populated; views and their triggers are ignored.
* **Migration Tables Ignored**: Schema-versioning tables from **Flyway** (`flyway_schema_history`, `schema_version`) and **Liquibase** (`databasechangelog`, `databasechangeloglock`) are skipped automatically.

---

## 🛠️ Usage Guide

### 1. Command Options

* `--host` : Target server hostname, DNS, or `localhost`
* `--port` : PostgreSQL network port
* `--user` : Username credential
* `--pass` : Password credential
* `--name` : Target database name
* `--schema` : Target schema name (default: `public`)
* `--rows` : Number of rows to generate per table (default: `1`)

### 2. Concrete Examples

#### 🔹 Case 1: Single row per table (default)
```bash
./pg-data-generator.sh \
--host localhost \
--port 5432 \
--user postgres \
--pass MySecurePass \
--name smartsupply \
--schema smart_supply
```

#### 🔹 Case 2: Bulk generation (100 rows per table)
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

---

## 🔍 Output & Execution

The generated script is written to the `results/` directory:

* `results/<db_name>_random_data.sql`

The file is wrapped in a single transaction (`BEGIN; ... COMMIT;`) with `\set ON_ERROR_STOP on`. Run it against the same database, for example:

```bash
psql -h localhost -p 5432 -U postgres -d smartsupply \
  -f results/smartsupply_random_data.sql
```

---

## ⚙️ How It Works

1. **Metadata extraction** — three catalogue queries collect the columns (with type and max length), the foreign-key graph, and the `CHECK` constraint definitions.
2. **Resolution & generation** — an inline Node.js engine builds the dependency graph, computes effective column lengths, parses enumerations, then walks the tables to emit type-correct `INSERT` statements in dependency order.
3. **Cleanup** — the temporary metadata files are removed, leaving only the final SQL script.

---

## 📋 Requirements

* **Docker** (the script pulls and runs `postgres:latest` with `--network host`).
* **Node.js** (used for the generation engine).
* Network access to the target PostgreSQL instance.

---

## ⚠️ Notes

* Generated data is intentionally random and **not semantically meaningful** — it only guarantees valid types and constraint compliance.
* Foreign keys pointing at auto-generated (`serial`/`identity`) primary keys are satisfied at runtime via `SELECT ... ORDER BY random() LIMIT 1` sub-queries.
* Thanks to `ON CONFLICT DO NOTHING`, the exact number of persisted rows per table may be lower than `--rows` for junction tables with composite keys — this is expected.
