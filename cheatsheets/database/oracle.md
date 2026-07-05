# Oracle Database Cheatsheet

> Practical Oracle notes for SQL, PL/SQL, and SQL*Plus. For standard SQL topics like joins and window functions, see `sql.md`.

---

## SQL*Plus / SQLcl

```bash
sqlplus user/password@//host:1521/servicename
sqlplus /nolog                      # then: CONNECT user/pass@db
sql user/password@host:1521/service # SQLcl (modern CLI)
```

### Useful SQL*Plus commands
| Command                         | Description                     |
|---------------------------------|---------------------------------|
| `DESC table`                    | describe a table                |
| `SET LINESIZE 200`              | widen output                    |
| `SET PAGESIZE 50`               | rows per page                   |
| `SET SERVEROUTPUT ON`           | show `DBMS_OUTPUT`              |
| `SHOW USER`                     | current user                    |
| `@script.sql`                   | run a script file               |
| `SPOOL out.txt` / `SPOOL OFF`   | capture output to file          |
| `/`                             | re-run last statement           |
| `EXIT`                          | quit                            |

---

## Oracle-isms (things that differ)

```sql
-- DUAL: the one-row dummy table
SELECT SYSDATE FROM dual;
SELECT 1 + 1 FROM dual;

-- Pagination (12c+)
SELECT * FROM orders ORDER BY id OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
-- Legacy pagination
SELECT * FROM (SELECT a.*, ROWNUM rn FROM (SELECT * FROM orders ORDER BY id) a WHERE ROWNUM <= 30) WHERE rn > 20;

-- NULL handling
SELECT NVL(commission, 0) FROM emp;          -- like COALESCE for one value
SELECT NVL2(commission, 'has', 'none') FROM emp;
SELECT COALESCE(a, b, c) FROM t;             -- also supported

-- String concat
SELECT first_name || ' ' || last_name FROM emp;   -- || or CONCAT()
```

> **Warning:** In Oracle, an **empty string `''` IS treated as `NULL`** — a classic surprise.

---

## MERGE (Upsert)

```sql
MERGE INTO users u
USING (SELECT 1 AS id, 'a@x.com' AS email FROM dual) src
ON (u.id = src.id)
WHEN MATCHED THEN UPDATE SET u.email = src.email
WHEN NOT MATCHED THEN INSERT (id, email) VALUES (src.id, src.email);
```

---

## Sequences & Identity

```sql
CREATE SEQUENCE user_seq START WITH 1 INCREMENT BY 1;
SELECT user_seq.NEXTVAL FROM dual;
INSERT INTO users (id, name) VALUES (user_seq.NEXTVAL, 'Ana');

-- 12c+ identity column
CREATE TABLE users (
  id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR2(100)
);
```

---

## Dates

```sql
SELECT SYSDATE, SYSTIMESTAMP FROM dual;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual;
SELECT TO_DATE('2024-01-15', 'YYYY-MM-DD') FROM dual;
SELECT ADD_MONTHS(SYSDATE, 3), MONTHS_BETWEEN(d1, d2) FROM dual;
SELECT EXTRACT(YEAR FROM SYSDATE) FROM dual;
SELECT SYSDATE + INTERVAL '7' DAY FROM dual;
```

---

## PL/SQL Basics

```sql
-- Anonymous block
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM users;
  DBMS_OUTPUT.PUT_LINE('Users: ' || v_count);
EXCEPTION
  WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('none');
END;
/

-- Stored procedure
CREATE OR REPLACE PROCEDURE deactivate_user(p_id IN NUMBER) AS
BEGIN
  UPDATE users SET active = 0 WHERE id = p_id;
  COMMIT;
END;
/

-- Function
CREATE OR REPLACE FUNCTION full_name(p_id NUMBER) RETURN VARCHAR2 AS
  v_name VARCHAR2(200);
BEGIN
  SELECT first_name || ' ' || last_name INTO v_name FROM emp WHERE id = p_id;
  RETURN v_name;
END;
/
```

---

## Performance & Introspection

```sql
EXPLAIN PLAN FOR SELECT ...;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT * FROM user_tables;         -- your tables
SELECT * FROM all_tab_columns WHERE table_name = 'USERS';
SELECT * FROM user_indexes;
SELECT * FROM v$session;           -- active sessions (needs privileges)

-- Optimizer hints
SELECT /*+ INDEX(u idx_users_email) */ * FROM users u WHERE email = 'a@x.com';
```

* Data dictionary prefixes: `USER_*` (owned), `ALL_*` (accessible), `DBA_*` (all, privileged).
* Gather stats: `EXEC DBMS_STATS.GATHER_TABLE_STATS('SCHEMA','USERS');`

---

## Common Gotchas

* `''` = `NULL` (empty string is null) — unique to Oracle among major DBs.
* Identifiers are **UPPERCASE** by default; quoting makes them case-sensitive.
* Use `VARCHAR2`, not `VARCHAR` (reserved for future use / different semantics).
* `NUMBER` is the catch-all numeric type; no native boolean in SQL (use `NUMBER(1)` or `CHAR(1)`).
* Every PL/SQL block ends with `/` on its own line in SQL*Plus.
* DDL implicitly commits the current transaction.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
