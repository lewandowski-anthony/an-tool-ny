# SQL Cheatsheet (Standard / Cross-DB)

> A practical reference for standard SQL commands, patterns, and best practices that work across most relational databases, including PostgreSQL, MySQL, Oracle, and SQL Server. Engine-specific details live in their own cheatsheets.

---

## Querying (SELECT)

```sql
SELECT col1, col2 FROM users;
SELECT * FROM users WHERE age >= 18;
SELECT DISTINCT country FROM users;
SELECT name, age FROM users ORDER BY age DESC, name ASC;
SELECT * FROM users LIMIT 10 OFFSET 20;        -- pagination (PG/MySQL)
SELECT * FROM users FETCH FIRST 10 ROWS ONLY;  -- standard SQL / Oracle
```

### Filtering
```sql
WHERE age BETWEEN 18 AND 65
WHERE country IN ('FR', 'BE', 'CH')
WHERE name LIKE 'A%'          -- starts with A
WHERE email IS NULL
WHERE NOT active
WHERE created_at > CURRENT_DATE - INTERVAL '7' DAY
```

---

## Joins

```sql
SELECT o.id, u.name
FROM orders o
JOIN users u        ON u.id = o.user_id      -- INNER JOIN
LEFT JOIN address a ON a.user_id = u.id;      -- keep all orders/users

-- Join types:
-- INNER  → only matching rows
-- LEFT   → all left rows + matches (NULLs otherwise)
-- RIGHT  → all right rows + matches
-- FULL   → everything, matched where possible
-- CROSS  → cartesian product
```

> **Tip:** Always qualify columns with table aliases in joins. It keeps queries clearer and avoids ambiguity.

---

## Aggregation & Grouping

```sql
SELECT country, COUNT(*) AS total, AVG(age) AS avg_age
FROM users
GROUP BY country
HAVING COUNT(*) > 100          -- filter groups (WHERE filters rows)
ORDER BY total DESC;
```

Common aggregates: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`.

> **Tip:** `WHERE` filters **before** grouping; `HAVING` filters **after**.

---

## Window Functions

```sql
SELECT
  name, department, salary,
  RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS rnk,
  AVG(salary)  OVER (PARTITION BY department)                      AS dept_avg,
  LAG(salary)  OVER (ORDER BY hired_at)                            AS prev_salary
FROM employees;
```

Useful window functions: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`, `SUM/AVG OVER`, `NTILE`.

---

## Subqueries & CTEs

```sql
-- Common Table Expression (readable, composable)
WITH recent AS (
  SELECT * FROM orders WHERE created_at > CURRENT_DATE - INTERVAL '30' DAY
)
SELECT user_id, COUNT(*) FROM recent GROUP BY user_id;

-- Subquery in WHERE
SELECT * FROM users
WHERE id IN (SELECT user_id FROM orders WHERE total > 100);
```

> **Tip:** Prefer CTEs over deeply nested subqueries when they make the query easier to read. Recursive CTEs (`WITH RECURSIVE`) handle hierarchies and graphs.

---

## Data Modification (DML)

```sql
INSERT INTO users (name, email) VALUES ('Ana', 'ana@x.com');
INSERT INTO users (name, email) VALUES ('A','a@x'), ('B','b@x');  -- multi-row

UPDATE users SET active = false WHERE last_login < CURRENT_DATE - INTERVAL '1' YEAR;

DELETE FROM users WHERE id = 42;

-- Upsert (syntax varies by engine — see per-DB cheatsheets)
```

> **Warning:** **Always run `UPDATE`/`DELETE` with a `WHERE`.** Test with a `SELECT` using the same filter first.

---

## Schema (DDL)

```sql
CREATE TABLE users (
  id         BIGINT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(255) UNIQUE,
  age        INT CHECK (age >= 0),
  country_id INT REFERENCES countries(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users RENAME COLUMN name TO full_name;
DROP TABLE users;
TRUNCATE TABLE users;         -- fast delete-all (no per-row triggers/rollback log)
```

### Constraints
`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`, `DEFAULT`.

---

## Indexes

```sql
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_email_uq ON users(email);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);  -- composite
DROP INDEX idx_users_email;
```

* Index columns used in `WHERE`, `JOIN`, `ORDER BY`.
* **Composite index order matters** — leftmost columns must be used to benefit.
* Over-indexing slows writes and wastes space; index deliberately.

---

## Transactions

```sql
BEGIN;                         -- or START TRANSACTION
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;                        -- or ROLLBACK to undo
```

**ACID**: Atomicity, Consistency, Isolation, Durability.
Isolation levels: `READ UNCOMMITTED` → `READ COMMITTED` → `REPEATABLE READ` → `SERIALIZABLE` (stronger = safer, slower).

---

## Best Practices

* **Never `SELECT *`** in production code — name columns (faster, stable, self-documenting).
* Use **parameterized queries** to prevent SQL injection — never string-concatenate user input.
* Filter early, project only needed columns.
* Use `EXPLAIN` / `EXPLAIN ANALYZE` to understand query plans and missing indexes.
* Normalize to reduce redundancy; denormalize deliberately for read performance.
* Prefer `EXISTS` over `IN` for large subqueries.
* Use `COALESCE(x, default)` to handle NULLs; remember `NULL != NULL`.
* Keep transactions short to reduce lock contention.

---

## Common Gotchas

* `NULL` comparisons need `IS NULL` / `IS NOT NULL`, not `= NULL`.
* `COUNT(col)` ignores NULLs; `COUNT(*)` counts all rows.
* Integer division truncates in many engines (`5/2 = 2`) — cast to decimal.
* `WHERE` can't reference column aliases from the SELECT in most engines (use the expression or a subquery/CTE).
* String comparison case sensitivity depends on collation and engine.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
