# MySQL Cheatsheet

> Practical MySQL notes for the CLI, common syntax, and database-specific quirks. For standard SQL topics like joins, window functions, and transactions, see `sql.md`; most of this also applies to MariaDB.

---

## CLI (mysql)

```bash
mysql -h localhost -P 3306 -u root -p mydb        # connect (prompts for password)
mysql -u root -p'secret' mydb                      # inline password (no space!)
mysql -u root -p mydb < script.sql                 # run a script
mysqldump -u root -p mydb > backup.sql             # backup
mysql -u root -p mydb < backup.sql                 # restore
```

### Client commands
| Command            | Description              |
|--------------------|--------------------------|
| `SHOW DATABASES;`  | list databases           |
| `USE mydb;`        | switch database          |
| `SHOW TABLES;`     | list tables              |
| `DESCRIBE users;`  | describe table (or `DESC`)|
| `SHOW COLUMNS FROM users;` | columns          |
| `SHOW INDEX FROM users;`   | indexes          |
| `SHOW CREATE TABLE users;` | full DDL         |
| `SHOW PROCESSLIST;`| active connections       |
| `STATUS;`          | server/connection info   |
| `source file.sql`  | run a script file        |
| `\G`               | vertical output (end query with `\G`) |

---

## Data Types (highlights)

* **Integers**: `TINYINT`, `INT`, `BIGINT` (+ `UNSIGNED`).
* **Auto increment**: `INT AUTO_INCREMENT PRIMARY KEY`.
* **Decimal/money**: `DECIMAL(10,2)` (never `FLOAT` for money).
* **Text**: `VARCHAR(n)`, `TEXT`, `LONGTEXT`.
* **Boolean**: `TINYINT(1)` / `BOOLEAN` (alias).
* **Dates**: `DATE`, `DATETIME`, `TIMESTAMP` (auto-UTC conversion), `YEAR`.
* **JSON**: native `JSON` type (5.7+).
* **Enum/Set**: `ENUM('a','b')`, `SET('x','y')`.

---

## Upsert & Insert Variants

```sql
-- Upsert
INSERT INTO users (id, email, name) VALUES (1, 'a@x', 'Ana')
ON DUPLICATE KEY UPDATE email = VALUES(email), name = VALUES(name);
-- 8.0.19+ alias form:
INSERT INTO users (id, email) VALUES (1, 'a@x') AS new
ON DUPLICATE KEY UPDATE email = new.email;

INSERT IGNORE INTO users (email) VALUES ('a@x');   -- skip on duplicate/error
REPLACE INTO users (id, email) VALUES (1, 'a@x');  -- delete+insert (careful!)
```

---

## Dates & Strings

```sql
SELECT NOW(), CURDATE(), CURTIME();
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s');
SELECT DATE_ADD(NOW(), INTERVAL 7 DAY), DATEDIFF(d1, d2);
SELECT YEAR(NOW()), MONTH(NOW());
SELECT CONCAT(first_name, ' ', last_name);
SELECT GROUP_CONCAT(name SEPARATOR ', ') FROM users;   -- aggregate strings
SELECT IFNULL(commission, 0), COALESCE(a, b);
```

---

## JSON (5.7+)

```sql
SELECT data->>'$.name' AS name,          -- unquoted extract
       data->'$.age'   AS age            -- keeps JSON type
FROM events;

UPDATE events SET data = JSON_SET(data, '$.active', true) WHERE id = 1;
SELECT * FROM events WHERE JSON_CONTAINS(data, '"admin"', '$.roles');
SELECT * FROM events WHERE data->>'$.status' = 'paid';
```

---

## Performance & Introspection

```sql
EXPLAIN SELECT ...;                    -- query plan
EXPLAIN ANALYZE SELECT ...;            -- 8.0.18+ actual execution
SHOW INDEX FROM users;
ANALYZE TABLE users;                   -- refresh stats
OPTIMIZE TABLE users;                  -- defragment
SHOW VARIABLES LIKE 'innodb%';
SHOW ENGINE INNODB STATUS\G
```

* **Use InnoDB** (default) — supports transactions, FKs, row-level locking. Avoid MyISAM for new work.
* Add indexes on `WHERE`/`JOIN`/`ORDER BY` columns; composite index order matters.
* Enable the slow query log to find bottlenecks.
* Prefer `utf8mb4` charset (real UTF-8, incl. emoji) — not legacy `utf8`.

---

## Transactions & Locking

```sql
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;   -- or ROLLBACK

SELECT * FROM users WHERE id = 1 FOR UPDATE;   -- row lock
```
Default isolation level: **`REPEATABLE READ`** (differs from PostgreSQL's `READ COMMITTED`).

---

## Users & Privileges

```sql
CREATE USER 'app'@'%' IDENTIFIED BY 'secret';
GRANT SELECT, INSERT, UPDATE ON mydb.* TO 'app'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'app'@'%';
DROP USER 'app'@'%';
```

> **Tip:** The host part matters: `'app'@'localhost'` ≠ `'app'@'%'` (any host).

---

## Common Gotchas

* Table name case sensitivity depends on the **OS/filesystem** (`lower_case_table_names`): case-sensitive on Linux, insensitive on macOS/Windows — a portability trap.
* `utf8` is a 3-byte legacy alias — always use **`utf8mb4`** for full Unicode.
* `TIMESTAMP` auto-converts to UTC and has a 2038 limit; `DATETIME` does not convert.
* `GROUP BY` was historically lenient (`ONLY_FULL_GROUP_BY` now default in 5.7+ enforces correctness).
* `REPLACE INTO` and `INSERT ... ON DUPLICATE` differ: REPLACE deletes then inserts (fires triggers, resets other columns).
* No native `RETURNING` clause (unlike PostgreSQL); use `LAST_INSERT_ID()`.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
