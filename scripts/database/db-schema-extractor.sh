#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR=""

DB_TYPE=""
DB_HOST=""
DB_PORT=""
DB_USER=""
DB_PASS=""
DB_NAME=""

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --type <type>        Database type (mysql | postgres | oracle | mongo)"
    echo "  --host <host>        Database host address / DNS"
    echo "  --port <port>        Database port"
    echo "  --user <user>        Database username"
    echo "  --pass <password>    Database password"
    echo "  --name <db_name>     Database name (SID/Service Name for Oracle)"
    echo "  -o, --output <dir>   Output directory (Default: 'results' folder in script root)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type) DB_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        --host) DB_HOST="$2"; shift 2 ;;
        --port) DB_PORT="$2"; shift 2 ;;
        --user) DB_USER="$2"; shift 2 ;;
        --pass) DB_PASS="$2"; shift 2 ;;
        --name) DB_NAME="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$DB_TYPE" || -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_NAME" ]]; then
    echo "Error: Missing required parameters."
    usage
fi

OUTPUT_DIR=${OUTPUT_DIR:-"${SCRIPT_DIR}/results"}
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="${OUTPUT_DIR}/${DB_NAME}_schema.sql"
rm -f "$OUTPUT_FILE"

echo "Connecting to $DB_TYPE ($DB_NAME) on $DB_HOST:$DB_PORT..."

if [ "$DB_TYPE" = "mysql" ]; then
    echo "Extracting MySQL schema..."
    docker run --rm --network host \
        -e MYSQL_PWD="$DB_PASS" \
        mysql:latest \
        mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --no-data "$DB_NAME" > "$OUTPUT_FILE" 2>/dev/null

elif [ "$DB_TYPE" = "postgres" ]; then
    echo "Extracting PostgreSQL schema..."
    docker run --rm --network host \
        -e PGPASSWORD="$DB_PASS" \
        postgres:latest \
        pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --schema-only "$DB_NAME" > "$OUTPUT_FILE" 2>/dev/null

elif [ "$DB_TYPE" = "oracle" ]; then
    echo "Extracting Oracle DB schema (Metadata definitions)..."
    docker run --rm --network host \
        gvenzl/oracle-free:latest \
        exp ${DB_USER}/${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME} file=/dev/stdout rows=n 2>/dev/null > "$OUTPUT_FILE"

elif [ "$DB_TYPE" = "mongo" ]; then
    OUTPUT_FILE="${OUTPUT_DIR}/${DB_NAME}_mongo_schema.json"
    echo "Extracting MongoDB metadata (Collections & Indexes structure)..."
    docker run --rm --network host \
        mongo:latest \
        mongodump --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USER" --password "$DB_PASS" --db "$DB_NAME" --noData --archive 2>/dev/null > "$OUTPUT_FILE"
else
    echo "ERROR: Unsupported database type '$DB_TYPE'."
    exit 1
fi

if [ -s "$OUTPUT_FILE" ]; then
    echo "Success! Schema extracted into: $OUTPUT_FILE"
else
    echo "ERROR: Failed to extract schema. Verify your credentials, port, and connectivity."
    rm -f "$OUTPUT_FILE"
    exit 1
fi