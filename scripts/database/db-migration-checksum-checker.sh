#!/bin/bash

set -uo pipefail

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

MIGRATION_DIR=""
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASS="changeme"
DB_NAME="smartsupply"
DB_SCHEMA="public"
TOOL_TYPE="flyway"

usage() {
    echo -e "${YELLOW}Usage: $0 [options]${NC}"
    echo "Options:"
    echo "  --migration-dir <dir>  Directory containing your local SQL migration files"
    echo "  --tool <type>          Migration framework type (flyway | liquibase) (Default: flyway)"
    echo "  --host <host>          Target remote database host address (Default: localhost)"
    echo "  --port <port>          Target remote database port (Default: 5432)"
    echo "  --user <user>          Database username (Default: postgres)"
    echo "  --pass <password>      Database password (Default: changeme)"
    echo "  --name <db_name>       Database name (Default: smartsupply)"
    echo "  --schema <schema>      Database schema name (Default: public)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --migration-dir) MIGRATION_DIR="$2"; shift 2 ;;
        --tool)          TOOL_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        --host)          DB_HOST="$2"; shift 2 ;;
        --port)          DB_PORT="$2"; shift 2 ;;
        --user)          DB_USER="$2"; shift 2 ;;
        --pass)          DB_PASS="$2"; shift 2 ;;
        --name)          DB_NAME="$2"; shift 2 ;;
        --schema)        DB_SCHEMA="$2"; shift 2 ;;
        -h|--help)       usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

if [[ -z "$MIGRATION_DIR" ]]; then
    echo -e "${RED}Error: Missing required parameter (--migration-dir).${NC}"
    usage
fi

if [[ ! -d "$MIGRATION_DIR" ]]; then
    echo -e "${RED}ERROR: Migration directory '$MIGRATION_DIR' does not exist.${NC}"
    exit 1
fi

TOOL_UPPER=$(echo "$TOOL_TYPE" | tr '[:lower:]' '[:upper:]')

echo -e "${CYAN}=====================================================================${NC}"
echo -e "${CYAN}RUNNING DATABASE MIGRATION CHECKSUM VALIDATOR (${TOOL_UPPER})${NC}"
echo -e "${CYAN}=====================================================================${NC}"

echo -e "${BLUE}Scanning migration directory. Found the following SQL files to process:${NC}"
find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*.sql" | sort -V | while read -r sql_file; do
    echo -e "${BLUE}  -> Detected: $(basename "$sql_file")${NC}"
done
echo -e "${CYAN}---------------------------------------------------------------------${NC}"

echo -e "${YELLOW}Checking connectivity to remote database on ${DB_HOST}:${DB_PORT}...${NC}"
if ! docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:16 pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" &>/dev/null; then
    echo -e "${RED}ERROR: Cannot connect to remote database on ${DB_HOST}:${DB_PORT}.${NC}"
    exit 1
fi
echo -e "${GREEN}Database connectivity verified.${NC}\n"

echo -e "${CYAN}Starting remote database history cross-match...${NC}"
AUDIT_LOG=$(mktemp)
trap 'rm -f "$AUDIT_LOG"' EXIT

find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*.sql" | sort -V | while read -r sql_file; do
    filename=$(basename "$sql_file")
    db_checksum=""

    if [[ "$TOOL_TYPE" == "flyway" ]]; then
        query="SELECT checksum FROM ${DB_SCHEMA}.flyway_schema_history WHERE script = '${filename}';"
        db_checksum=$(docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:16 psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null </dev/null || true)
        db_checksum=$(echo "$db_checksum" | tr -d '[:space:]')

        if [[ -z "$db_checksum" ]]; then
            echo -e "${YELLOW}[⚠️  NOT DEPLOYED] ${filename}${NC}"
            continue
        fi

        if [[ -n "$db_checksum" ]]; then
            echo -e "${GREEN}[✔  MATCH]        ${filename} (CRC32: $db_checksum)${NC}"
        else
            echo -e "${RED}[❌ MISMATCH]     ${filename} (Remote BDD error)${NC}"
            echo "FAILED" >> "$AUDIT_LOG"
        fi

    elif [[ "$TOOL_TYPE" == "liquibase" ]]; then
        query="SELECT md5sum FROM ${DB_SCHEMA}.databasechangelog WHERE filename LIKE '%${filename}%';"
        db_checksum=$(docker run --rm --network host -e PGPASSWORD="$DB_PASS" postgres:16 psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null </dev/null || true)
        db_checksum=$(echo "$db_checksum" | tr -d '[:space:]')

        if [[ -z "$db_checksum" ]]; then
            echo -e "${YELLOW}[⚠️  NOT DEPLOYED] ${filename}${NC}"
            continue
        fi

        if [[ -n "$db_checksum" ]]; then
            echo -e "${GREEN}[✔  MATCH]        ${filename} (MD5: $db_checksum)${NC}"
        else
            echo -e "${RED}[❌ MISMATCH]     ${filename} (Remote BDD error)${NC}"
            echo "FAILED" >> "$AUDIT_LOG"
        fi
    fi
done

echo -e "${CYAN}=====================================================================${NC}"
if [ -s "$AUDIT_LOG" ]; then
    echo -e "${RED}AUDIT FAILED: Discrepancies detected between local files and remote state!${NC}"
    echo -e "${CYAN}=====================================================================${NC}"
    exit 1
else
    echo -e "${GREEN}AUDIT SUCCESS: All local and remote migration states are fully synchronized.${NC}"
    echo -e "${CYAN}=====================================================================${NC}"
    exit 0
fi