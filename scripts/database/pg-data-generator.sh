#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR=""

DB_HOST=""
DB_PORT=""
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_SCHEMA="public"
ROWS="1"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --host <host>        PostgreSQL host address / DNS"
    echo "  --port <port>        PostgreSQL port"
    echo "  --user <user>        PostgreSQL username"
    echo "  --pass <password>    PostgreSQL password"
    echo "  --name <db_name>     PostgreSQL database name"
    echo "  --schema <schema>    PostgreSQL schema name (default: public)"
    echo "  --rows <count>       Number of rows to generate per table (default: 1)"
    echo "  -o, --output <dir>   Output directory (Default: 'results' folder in script root)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host) DB_HOST="$2"; shift 2 ;;
        --port) DB_PORT="$2"; shift 2 ;;
        --user) DB_USER="$2"; shift 2 ;;
        --pass) DB_PASS="$2"; shift 2 ;;
        --name) DB_NAME="$2"; shift 2 ;;
        --schema) DB_SCHEMA="$2"; shift 2 ;;
        --rows) ROWS="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_NAME" ]]; then
    usage
fi

if ! [[ "$ROWS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: --rows must be a positive integer."
    exit 1
fi

OUTPUT_DIR=${OUTPUT_DIR:-"${SCRIPT_DIR}/results"}
mkdir -p "$OUTPUT_DIR"

COLUMNS_META_FILE="${OUTPUT_DIR}/${DB_NAME}_columns.txt"
FK_MAP_FILE="${OUTPUT_DIR}/${DB_NAME}_fk_map.txt"
CHECK_MAP_FILE="${OUTPUT_DIR}/${DB_NAME}_check_map.txt"
OUTPUT_FILE="${OUTPUT_DIR}/${DB_NAME}_random_data.sql"

cleanup_metadata() {
    rm -f "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$CHECK_MAP_FILE"
}

run_query() {
    local query="$1"
    local output="$2"
    docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:latest \
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" > "$output" 2>/dev/null
}

rm -f "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$CHECK_MAP_FILE" "$OUTPUT_FILE"

echo "Step 1: Querying database system catalogue metadata..."

COLUMNS_QUERY="SELECT c.table_name || '|' || c.column_name || '|' || c.data_type || '|' || COALESCE(c.character_maximum_length::text, '') FROM information_schema.columns c JOIN information_schema.tables t ON t.table_name = c.table_name AND t.table_schema = c.table_schema WHERE c.table_schema = '${DB_SCHEMA}' AND t.table_type = 'BASE TABLE' AND lower(c.table_name) NOT IN ('flyway_schema_history', 'schema_version', 'databasechangelog', 'databasechangeloglock') AND (c.column_default IS NULL OR c.column_default NOT LIKE 'nextval%') AND c.is_identity = 'NO' ORDER BY c.table_name, c.ordinal_position;"
run_query "$COLUMNS_QUERY" "$COLUMNS_META_FILE"

FK_QUERY="SELECT nk.relname AS child_table, a.attname AS child_column, nr.relname AS parent_table, pa.attname AS parent_column FROM pg_constraint c JOIN pg_class nk ON c.conrelid = nk.oid JOIN pg_class nr ON c.confrelid = nr.oid JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1] JOIN pg_attribute pa ON pa.attrelid = c.confrelid AND pa.attnum = c.confkey[1] WHERE c.contype = 'f' AND c.connamespace = (SELECT oid FROM pg_namespace WHERE nspname = '${DB_SCHEMA}');"
run_query "$FK_QUERY" "$FK_MAP_FILE"

CHECK_QUERY="SELECT rel.relname || '|' || pg_get_constraintdef(c.oid) FROM pg_constraint c JOIN pg_class rel ON c.conrelid = rel.oid WHERE c.contype = 'c' AND c.connamespace = (SELECT oid FROM pg_namespace WHERE nspname = '${DB_SCHEMA}');"
run_query "$CHECK_QUERY" "$CHECK_MAP_FILE"

if [ ! -s "$COLUMNS_META_FILE" ]; then
    echo "Error: Failed to extract structural info or schema '${DB_SCHEMA}' is empty."
    cleanup_metadata
    exit 1
fi

echo "Step 2: Resolving dependencies and generating random data (${ROWS} row(s) per table)..."

node -e '
const fs = require("fs");

const readLines = (path) => (path && fs.existsSync(path))
    ? fs.readFileSync(path, "utf-8").split("\n").map(l => l.trim()).filter(Boolean)
    : [];

const rawColumns = readLines(process.argv[1]);
const rawFKs = readLines(process.argv[2]);
const outputFile = process.argv[3];
const schemaName = process.argv[4];
const rawChecks = readLines(process.argv[5]);
const rowCount = Math.max(1, parseInt(process.argv[6] || "1", 10));

const tablesList = new Set();
const columnsMap = {};
const childToParent = {};
const allowedValues = {};
const effLen = {};

for (const line of rawColumns) {
    const [table, col, type, maxLen] = line.split("|");
    tablesList.add(table);
    if (!columnsMap[table]) columnsMap[table] = [];
    columnsMap[table].push({ name: col, type: type, maxLen: maxLen ? parseInt(maxLen, 10) : null });
}

for (const line of rawFKs) {
    const [childTable, childCol, parentTable, parentCol] = line.split("|");
    if (!childToParent[childTable]) childToParent[childTable] = {};
    childToParent[childTable][childCol] = { parentTable, parentCol };
}

for (const table in columnsMap) {
    effLen[table] = {};
    for (const col of columnsMap[table]) effLen[table][col.name] = col.maxLen;
}
let changed = true;
while (changed) {
    changed = false;
    for (const childTable in childToParent) {
        for (const childCol in childToParent[childTable]) {
            const { parentTable, parentCol } = childToParent[childTable][childCol];
            const childLen = effLen[childTable] ? effLen[childTable][childCol] : undefined;
            if (childLen == null) continue;
            if (!effLen[parentTable]) continue;
            const cur = effLen[parentTable][parentCol];
            const next = (cur == null) ? childLen : Math.min(cur, childLen);
            if (next !== cur) { effLen[parentTable][parentCol] = next; changed = true; }
        }
    }
}

for (const line of rawChecks) {
    const sepIndex = line.indexOf("|");
    if (sepIndex === -1) continue;
    const table = line.slice(0, sepIndex);
    const def = line.slice(sepIndex + 1);
    if (!/ANY\s*\(+\s*ARRAY\[/i.test(def)) continue;
    const colMatch = def.match(/\(+\s*"?(\w+)"?\s*\)*::text\s*=\s*ANY/i);
    if (!colMatch) continue;
    const colName = colMatch[1];
    const values = [];
    const valueRegex = /\x27((?:[^\x27]|\x27\x27)*)\x27/g;
    let m;
    while ((m = valueRegex.exec(def)) !== null) {
        values.push(m[1].replace(/\x27\x27/g, "\x27"));
    }
    if (values.length > 0) {
        if (!allowedValues[table]) allowedValues[table] = {};
        allowedValues[table][colName] = values;
    }
}

const rand = (n) => Math.floor(Math.random() * n);
const randChars = (len, alphabet) => Array.from({length: len}, () => alphabet[rand(alphabet.length)]).join("");
const quote = (s) => `\x27${s}\x27`;

const LETTERS = "abcdefghijklmnopqrstuvwxyz";
const HEX = "0123456789abcdef";

const generateString = (maxLen) => quote(randChars(maxLen ? Math.min(maxLen, 8) : 8, LETTERS));
const generateUUID = () => {
    const y = "89ab"[rand(4)];
    return quote(`${randChars(8, HEX)}-${randChars(4, HEX)}-4${randChars(3, HEX)}-${y}${randChars(3, HEX)}-${randChars(12, HEX)}`);
};
const generateInt = () => rand(1000) + 1;
const generateBool = () => Math.random() > 0.5 ? "TRUE" : "FALSE";
const generateDate = () => {
    const y = 2000 + rand(25);
    const m = String(rand(12) + 1).padStart(2, "0");
    const d = String(rand(28) + 1).padStart(2, "0");
    return quote(`${y}-${m}-${d}`);
};
const generateJson = () => quote(`{"${randChars(5, LETTERS)}": ${rand(1000)}}`);

const columnMaxLen = (tableName, name, fallback) =>
    (effLen[tableName] && effLen[tableName][name] != null) ? effLen[tableName][name] : fallback;

const generateValue = (tableName, col) => {
    const t = col.type.toUpperCase();
    const name = col.name;
    const isUuid = t.includes("UUID") || t.includes("USER-DEFINED");

    if (childToParent[tableName] && childToParent[tableName][name]) {
        const link = childToParent[tableName][name];
        return `(SELECT ${link.parentCol} FROM ${schemaName}.${link.parentTable} ORDER BY random() LIMIT 1)`;
    }

    if (allowedValues[tableName] && allowedValues[tableName][name]) {
        const opts = allowedValues[tableName][name];
        return quote(opts[rand(opts.length)].replace(/\x27/g, "\x27\x27"));
    }

    if (name.toLowerCase() === "id" || isUuid) return generateUUID();
    if (t.includes("JSON")) return generateJson();
    if (t.includes("INT") || t.includes("NUMERIC")) return generateInt();
    if (t.includes("FLOAT") || t.includes("DOUBLE") || t.includes("DECIMAL")) return "12.50";
    if (t.includes("BOOL")) return generateBool();
    if (t.includes("TIME") || t.includes("DATE")) return generateDate();
    return generateString(columnMaxLen(tableName, name, col.maxLen));
};

const databaseRecordsStore = {};
const visiting = new Set();
const insertStatements = [];

function populateTable(tableName) {
    if (databaseRecordsStore[tableName]) return;
    if (visiting.has(tableName)) return;
    visiting.add(tableName);
    const columns = columnsMap[tableName];
    if (!columns) { visiting.delete(tableName); return; }

    if (childToParent[tableName]) {
        for (const colName in childToParent[tableName]) {
            const parentTable = childToParent[tableName][colName].parentTable;
            if (!databaseRecordsStore[parentTable]) populateTable(parentTable);
        }
    }

    const colList = columns.map(c => c.name).join(", ");
    const rows = [];
    for (let i = 0; i < rowCount; i++) {
        const rowValues = [];
        const generatedRowObject = {};
        for (const col of columns) {
            const val = generateValue(tableName, col);
            rowValues.push(val);
            generatedRowObject[col.name] = val;
        }
        rows.push(generatedRowObject);
        insertStatements.push(`INSERT INTO ${schemaName}.${tableName} (${colList}) VALUES (${rowValues.join(", ")}) ON CONFLICT DO NOTHING;`);
    }

    databaseRecordsStore[tableName] = rows;
    visiting.delete(tableName);
}

for (const tableName of tablesList) populateTable(tableName);

const finalSql = `-- Mapped Dataset\n\\set ON_ERROR_STOP on\n\nBEGIN;\n\n` + insertStatements.join("\n") + `\n\nCOMMIT;\n`;
fs.writeFileSync(outputFile, finalSql, "utf-8");
' "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$OUTPUT_FILE" "$DB_SCHEMA" "$CHECK_MAP_FILE" "$ROWS"

cleanup_metadata
echo "Success! Executable SQL script generated at: $OUTPUT_FILE"