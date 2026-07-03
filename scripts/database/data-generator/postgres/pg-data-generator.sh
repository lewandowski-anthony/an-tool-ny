#!/bin/bash

set -uo pipefail

RESULT_DIR="results"
mkdir -p "$RESULT_DIR"

DB_HOST=""
DB_PORT=""
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_SCHEMA="public"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --host <host>        PostgreSQL host address / DNS"
    echo "  --port <port>        PostgreSQL port"
    echo "  --user <user>        PostgreSQL username"
    echo "  --pass <password>    PostgreSQL password"
    echo "  --name <db_name>     PostgreSQL database name"
    echo "  --schema <schema>    PostgreSQL schema name (default: public)"
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
        -h|--help) usage ;;
        *) echo "❌ Option inconnue: $1"; usage ;;
    esac
done

if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_NAME" ]]; then
    usage
fi

COLUMNS_META_FILE="${RESULT_DIR}/${DB_NAME}_columns.txt"
FK_MAP_FILE="${RESULT_DIR}/${DB_NAME}_fk_map.txt"
CHECK_MAP_FILE="${RESULT_DIR}/${DB_NAME}_check_map.txt"
OUTPUT_FILE="${RESULT_DIR}/${DB_NAME}_random_data.sql"

rm -f "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$CHECK_MAP_FILE" "$OUTPUT_FILE"

echo "📡 Step 1: Querying database system catalogue metadata..."

# 1. Extraction de toutes les colonnes de toutes les tables du schéma cible
COLUMNS_QUERY="SELECT c.table_name || '|' || c.column_name || '|' || c.data_type || '|' || COALESCE(c.character_maximum_length::text, '') FROM information_schema.columns c JOIN information_schema.tables t ON t.table_name = c.table_name AND t.table_schema = c.table_schema WHERE c.table_schema = '${DB_SCHEMA}' AND t.table_type = 'BASE TABLE' AND (c.column_default IS NULL OR c.column_default NOT LIKE 'nextval%') AND c.is_identity = 'NO' ORDER BY c.table_name, c.ordinal_position;"
docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:latest psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$COLUMNS_QUERY" > "$COLUMNS_META_FILE" 2>/dev/null

# 2. Extraction du graphe de clés étrangères (A pointe vers B sur telle colonne)
FK_QUERY="SELECT nk.relname AS child_table, a.attname AS child_column, nr.relname AS parent_table, pa.attname AS parent_column FROM pg_constraint c JOIN pg_class nk ON c.conrelid = nk.oid JOIN pg_class nr ON c.confrelid = nr.oid JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1] JOIN pg_attribute pa ON pa.attrelid = c.confrelid AND pa.attnum = c.confkey[1] WHERE c.contype = 'f' AND c.connamespace = (SELECT oid FROM pg_namespace WHERE nspname = '${DB_SCHEMA}');"
docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:latest psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$FK_QUERY" > "$FK_MAP_FILE" 2>/dev/null

# 2b. Extraction des CHECK constraints (pour respecter les valeurs autorisées de type énumération)
CHECK_QUERY="SELECT rel.relname || '|' || pg_get_constraintdef(c.oid) FROM pg_constraint c JOIN pg_class rel ON c.conrelid = rel.oid WHERE c.contype = 'c' AND c.connamespace = (SELECT oid FROM pg_namespace WHERE nspname = '${DB_SCHEMA}');"
docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:latest psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$CHECK_QUERY" > "$CHECK_MAP_FILE" 2>/dev/null

if [ ! -s "$COLUMNS_META_FILE" ]; then
    echo "❌ Error: Failed to extract structural info or scheme '${DB_SCHEMA}' is empty."
    rm -f "$COLUMNS_META_FILE" "$FK_MAP_FILE"
    exit 1
fi

echo "🎲 Step 2: Running inline recursive dependency builder..."

# 3. Moteur Node de résolution à la volée injecté directement
node -e '
const fs = require("fs");

const rawColumns = fs.readFileSync(process.argv[1], "utf-8").split("\n").map(c => c.trim()).filter(Boolean);
const rawFKs = fs.readFileSync(process.argv[2], "utf-8").split("\n").map(f => f.trim()).filter(Boolean);
const outputFile = process.argv[3];
const schemaName = process.argv[4];
const checkFile = process.argv[5];

const rawChecks = (checkFile && fs.existsSync(checkFile))
    ? fs.readFileSync(checkFile, "utf-8").split("\n").map(c => c.trim()).filter(Boolean)
    : [];

const tablesList = new Set();
const columnsMap = {};
const childToParent = {};
const allowedValues = {};

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

// Longueur effective : une valeur réutilisée via FK doit tenir dans la colonne enfant la plus étroite.
const effLen = {};
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

// Parsing des CHECK de type col = ANY (ARRAY[...]) enumeration
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

const generateString = (maxLen) => {
    const len = maxLen ? Math.min(maxLen, 8) : 8;
    return `\x27${Array.from({length: len}, () => "abcdefghijklmnopqrstuvwxyz"[Math.floor(Math.random() * 26)]).join("")}\x27`;
};
const generateUUID = () => {
    const h = "0123456789abcdef";
    const r = (len) => Array.from({length: len}, () => h[Math.floor(Math.random() * 16)]).join("");
    const y = "89ab"[Math.floor(Math.random() * 4)];
    return `\x27${r(8)}-${r(4)}-4${r(3)}-${y}${r(3)}-${r(12)}\x27`;
};
const generateInt = () => Math.floor(Math.random() * 1000) + 1;
const generateBool = () => Math.random() > 0.5 ? "TRUE" : "FALSE";
const generateDate = () => {
    const y = 2000 + Math.floor(Math.random() * 25);
    const m = String(Math.floor(Math.random() * 12) + 1).padStart(2, "0");
    const d = String(Math.floor(Math.random() * 28) + 1).padStart(2, "0");
    return `\x27${y}-${m}-${d}\x27`;
};
const generateJson = () => {
    const key = Array.from({length: 5}, () => "abcdefghijklmnopqrstuvwxyz"[Math.floor(Math.random() * 26)]).join("");
    return `\x27{"${key}": ${Math.floor(Math.random() * 1000)}}\x27`;
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

    // ALGORITHME DE RÉCURSION INTÉGRAL SANS CHAÎNE EN DUR
    if (childToParent[tableName]) {
        for (const colName in childToParent[tableName]) {
            const parentTable = childToParent[tableName][colName].parentTable;
            if (!databaseRecordsStore[parentTable]) {
                populateTable(parentTable);
            }
        }
    }

    const rowValues = [];
    const generatedRowObject = {};

    for (const col of columns) {
        const t = col.type.toUpperCase();
        const name = col.name;
        const isUuid = t.includes("UUID") || t.includes("USER-DEFINED");

        let val;

        if (childToParent[tableName] && childToParent[tableName][name]) {
            const link = childToParent[tableName][name];
            const parentRows = databaseRecordsStore[link.parentTable];
            const parentVal = parentRows && parentRows.length > 0 ? parentRows[0][link.parentCol] : undefined;
            if (parentVal !== undefined && parentVal !== null) {
                val = parentVal;
            } else {
                // PK parente auto-générée (serial/identity) : on cible la ligne réellement insérée
                val = `(SELECT ${link.parentCol} FROM ${schemaName}.${link.parentTable} ORDER BY ${link.parentCol} DESC LIMIT 1)`;
            }
        } else if (allowedValues[tableName] && allowedValues[tableName][name]) {
            const opts = allowedValues[tableName][name];
            const picked = opts[Math.floor(Math.random() * opts.length)].replace(/\x27/g, "\x27\x27");
            val = `\x27${picked}\x27`;
        } else {
            if (name.toLowerCase() === "id" || isUuid) val = generateUUID();
            else if (t.includes("JSON")) val = generateJson();
            else if (t.includes("INT") || t.includes("NUMERIC")) val = generateInt();
            else if (t.includes("FLOAT") || t.includes("DOUBLE") || t.includes("DECIMAL")) val = "12.50";
            else if (t.includes("BOOL")) val = generateBool();
            else if (t.includes("TIME") || t.includes("DATE")) val = generateDate();
            else val = generateString((effLen[tableName] && effLen[tableName][name] != null) ? effLen[tableName][name] : col.maxLen);
        }

        rowValues.push(val);
        generatedRowObject[name] = val;
    }

    databaseRecordsStore[tableName] = [generatedRowObject];
    visiting.delete(tableName);
    insertStatements.push(`INSERT INTO ${schemaName}.${tableName} (${columns.map(c => c.name).join(", ")}) VALUES (${rowValues.join(", ")});`);
}

for (const tableName of tablesList) {
    populateTable(tableName);
}

let finalSql = `-- 🧪 Mapped Dataset\n\\set ON_ERROR_STOP on\n\nBEGIN;\n\n` + insertStatements.join("\n") + `\n\nCOMMIT;\n`;
fs.writeFileSync(outputFile, finalSql, "utf-8");
' "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$OUTPUT_FILE" "$DB_SCHEMA" "$CHECK_MAP_FILE"

rm -f "$COLUMNS_META_FILE" "$FK_MAP_FILE" "$CHECK_MAP_FILE"
echo "🎉 Executable SQL script generated inside: $OUTPUT_FILE"