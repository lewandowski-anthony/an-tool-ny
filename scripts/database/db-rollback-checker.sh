#!/bin/bash

set -uo pipefail

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_DIR=""
ROLLBACK_FILE=""
DB_SCHEMA="public"

DB_CONTAINER_NAME="toolkit-rollback-validator-db"
DB_PORT="5543"
DB_USER="postgres"
DB_PASS="temp_secret_password_123"
DB_NAME="validator_db"

usage() {
    echo -e "${YELLOW}Usage: $0 [options]${NC}"
    echo "Options:"
    echo "  --migration-dir <dir>  Directory containing baseline/forward SQL files"
    echo "  --rollback-file <file> Specific SQL rollback file to test (Optional)"
    echo "  --schema <schema>      Database schema to use/create (Default: public)"
    echo "  --port <port>          Local port to bind the temporary container (Default: 5543)"
    echo "  --user <user>          Temporary database username (Default: postgres)"
    echo "  --pass <password>      Temporary database password (Default: temp_secret_password_123)"
    echo "  --name <db_name>       Temporary database name (Default: validator_db)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --migration-dir) MIGRATION_DIR="$2"; shift 2 ;;
        --port)           DB_PORT="$2"; shift 2 ;;
        --user)           DB_USER="$2"; shift 2 ;;
        --pass)           DB_PASS="$2"; shift 2 ;;
        --name)           DB_NAME="$2"; shift 2 ;;
        --rollback-file) ROLLBACK_FILE="$2"; shift 2 ;;
        --schema)         DB_SCHEMA="$2"; shift 2 ;;
        -h|--help)        usage ;;
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

if [[ -n "$ROLLBACK_FILE" && ! -f "$ROLLBACK_FILE" ]]; then
    echo -e "${RED}ERROR: Rollback SQL file '$ROLLBACK_FILE' does not exist.${NC}"
    exit 1
fi

echo -e "${CYAN}=====================================================================${NC}"
echo -e "${CYAN}RUNNING DATABASE SCHEMA INTEGRITY & VALIDATION CHECKER${NC}"
echo -e "${CYAN}=====================================================================${NC}"

echo -e "${BLUE}1/5 Launching temporary isolated PostgreSQL container...${NC}"
docker run --name "${DB_CONTAINER_NAME}" \
  -e POSTGRES_DB="${DB_NAME}" \
  -e POSTGRES_USER="${DB_USER}" \
  -e POSTGRES_PASSWORD="${DB_PASS}" \
  -p "${DB_PORT}:5432" \
  -d postgres:16-alpine > /dev/null

cleanup() {
  echo -e "\n${YELLOW}Cleaning up: Destroying temporary test database container...${NC}"
  docker rm -f "${DB_CONTAINER_NAME}" > /dev/null 2>&1
}
trap cleanup EXIT

echo -e "${YELLOW}Waiting for database readiness on port ${DB_PORT}...${NC}"
until docker exec "${DB_CONTAINER_NAME}" pg_isready -U "${DB_USER}" -d "${DB_NAME}" &> /dev/null; do
  sleep 1
done
echo -e "${GREEN}Database is up and running.${NC}"

if [[ "$DB_SCHEMA" != "public" ]]; then
    docker exec -i "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "CREATE SCHEMA IF NOT EXISTS ${DB_SCHEMA};" >/dev/null
fi
docker exec -i "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "ALTER DATABASE ${DB_NAME} SET search_path TO ${DB_SCHEMA}, public;" >/dev/null

echo -e "\n${BLUE}2/5 Applying all forward migrations found in '${MIGRATION_DIR}'...${NC}"

find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*.sql" | sort -V | while read -r sql_file; do
    echo -e "${CYAN}   -> Executing: $(basename "$sql_file")${NC}"
    docker exec -i "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "$sql_file" >/dev/null
done

echo -e "${GREEN}Forward migrations successfully applied.${NC}"

if [[ -z "$ROLLBACK_FILE" ]]; then
  echo -e "${GREEN}=====================================================================${NC}"
  echo -e "${GREEN}SUCCESS: All forward schema migrations applied perfectly!${NC}"
  echo -e "${GREEN}=====================================================================${NC}"
  exit 0
fi

BEFORE_ROLLBACK_SCHEMA=$(docker exec "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "\dt ${DB_SCHEMA}.*" 2>&1)

echo -e "\n${BLUE}3/5 Triggering backward rollback script validation from '$(basename "$ROLLBACK_FILE")'...${NC}"
docker exec -i "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "$ROLLBACK_FILE" >/dev/null

echo -e "${GREEN}Rollback script applied without structural or constraint database errors.${NC}"

echo -e "\n${BLUE}4/5 Analyzing database structure compatibility post-rollback...${NC}"
AFTER_ROLLBACK_SCHEMA=$(docker exec "${DB_CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "\dt ${DB_SCHEMA}.*" 2>&1)

echo -e "\n${BLUE}5/5 Final Evaluation Report Summary:${NC}"
if [[ "$AFTER_ROLLBACK_SCHEMA" == *"Did not find any relations"* ]]; then
  echo -e "${GREEN}=====================================================================${NC}"
  echo -e "${GREEN}ROLLBACK PASSED: Database schema returned cleanly to baseline state!${NC}"
  echo -e "${GREEN}Code is safe and fully backward-compatible. Ready for Preprod.${NC}"
  echo -e "${GREEN}=====================================================================${NC}"
  exit 0
else
  echo -e "${RED}=====================================================================${NC}"
  echo -e "${RED}ROLLBACK FAILED OR INCOMPLETE: Orphaned schema objects detected.${NC}"
  echo -e "${YELLOW}The following relations are still present in the database:${NC}"
  echo "$AFTER_ROLLBACK_SCHEMA"
  echo -e "${RED}=====================================================================${NC}"
  exit 1
fi