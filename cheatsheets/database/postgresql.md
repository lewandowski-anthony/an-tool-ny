# 🐘 PostgreSQL Cheatsheet

> A concise collection of PostgreSQL-specific commands, `psql` tips, and idioms. For standard SQL (joins, window functions, transactions), see `sql.md`.

---

## 💻 psql (CLI)

```bash
psql -h localhost -p 5432 -U postgres -d mydb    # connect
PGPASSWORD=secret psql -U postgres -d mydb        # password via env
psql "postgresql://user:pass@host:5432/db"        # connection URI
```

### Meta-commands (inside psql)
| Command        | Description                        |
|----------------|------------------------------------|
| `\l`           | list databases                     |
| `\c dbname`    | connect to database                |
| `\dt`          | list tables                        |
| `\d table`     | describe table                     |
| `\dn`          | list schemas                       |
| `\df`          | list functions                     |
| `\dv`          | list views                         |
| `\du`          | list roles/users                   |
| `\di`          | list indexes                       |
| `\x`           | toggle expanded (vertical) output  |
| `\timing`      | toggle query timing                |
| `\i file.sql`  | run a SQL script file              |
| `\copy`        | client-side import/export CSV      |
| `\q`           | quit                               |

> 💡 Run a script from disk with `\i /path/file.sql` (or `psql -f file.sql`). GUI tools may cache an editor buffer — running from the file is authoritative.

---

## 🧬 Data Types (highlights)

* **Serial/Identity**: `GENERATED ALWAYS AS IDENTITY` (modern) or `SERIAL`/`BIGSERIAL`.
* **UUID**: `uuid` type; generate with `gen_random_uuid()` (from `pgcrypto`) or `uuidv4()`.
* **JSON**: `json` (text) vs **`jsonb`** (binary, indexable — prefer this).
* **Arrays**: `int[]`, `text[]`.
* **Text**: `text` (unlimited) is fine — no perf penalty vs `varchar(n)`.
* **Timestamps**: prefer `timestamptz` (with time zone).
* **Enums**: `CREATE TYPE mood AS ENUM ('happy','sad');`

---

## 🆙 Upsert (ON CONFLICT)

```sql
INSERT INTO users (id, email, name)
VALUES (1, 'a@x.com', 'Ana')
ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email, name = EXCLUDED.name;

INSERT INTO users (email) VALUES ('a@x.com')
ON CONFLICT (email) DO NOTHING;
```

---

## 🧩 JSONB

```sql
SELECT data->>'name'          AS name,      -- text
       data->'address'->>'city' AS city,    -- nested
       data #>> '{tags,0}'    AS first_tag  -- path
FROM events;

SELECT * FROM events WHERE data @> '{"active": true}';  -- contains
CREATE INDEX idx_events_data ON events USING GIN (data);-- index jsonb
```

> 💡 `->` returns json, `->>` returns text. `@>` (containment) is GIN-indexable.

---

## 🪟 Powerful Features

```sql
-- Generate series
SELECT generate_series(1, 5);
SELECT generate_series('2024-01-01'::date, '2024-12-31', '1 month');

-- DISTINCT ON (first row per group)
SELECT DISTINCT ON (user_id) * FROM orders ORDER BY user_id, created_at DESC;

-- RETURNING (get back inserted/updated rows)
INSERT INTO users (name) VALUES ('Ana') RETURNING id, created_at;

-- Full-text search
SELECT * FROM articles WHERE to_tsvector('english', body) @@ to_tsquery('postgres');

-- LATERAL join
SELECT u.name, o.*
FROM users u
JOIN LATERAL (SELECT * FROM orders WHERE user_id = u.id ORDER BY created_at DESC LIMIT 3) o ON true;
```

---

## ⚡ Performance & Introspection

```sql
EXPLAIN ANALYZE SELECT ...;                 -- real plan + timings
VACUUM ANALYZE;                             -- reclaim space + update stats
REINDEX TABLE users;
SELECT * FROM pg_stat_activity;             -- current connections/queries
SELECT pg_size_pretty(pg_total_relation_size('users'));  -- table size
```

* Index types: `B-tree` (default), `GIN` (jsonb/arrays/FTS), `GiST`, `BRIN` (huge append-only tables), `Hash`.
* Partial index: `CREATE INDEX ... WHERE active`.
* Use `pg_stat_statements` extension to find slow queries.

---

## 🔐 Roles & Permissions

```sql
CREATE ROLE app LOGIN PASSWORD 'secret';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
GRANT USAGE ON SCHEMA public TO app;
```

---

## 🧠 Schemas & Search Path

```sql
CREATE SCHEMA reporting;
SET search_path TO reporting, public;
SELECT * FROM reporting.my_table;
```

---

## ⚠️ Common Gotchas

* Identifiers fold to **lowercase** unless double-quoted (`"MyTable"` ≠ `mytable`).
* `char(n)` is blank-padded and rarely what you want — use `text`/`varchar`.
* `views` that join multiple tables aren't auto-updatable — need `INSTEAD OF` triggers.
* `NULL` in `jsonb` vs SQL `NULL` are different beasts.
* Sequences aren't rolled back — gaps in serial IDs are normal.
* Default isolation is `READ COMMITTED`.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
