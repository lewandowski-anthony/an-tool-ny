#!/bin/bash

set -uo pipefail

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

COMPOSE_FILE="docker-compose.yml"
LOG_LEVEL="ERROR"
TAIL_LINES="all"
FOLLOW_MODE="false"

usage() {
    echo -e "${YELLOW}Usage: $0 [options]${NC}"
    echo "Options:"
    echo "  --level <type>         Log level to filter (ERROR | WARN | INFO | DEBUG) (Default: ERROR)"
    echo "  --file <path>          Path to the docker-compose.yml file (Default: docker-compose.yml)"
    echo "  --tail <number>        Number of lines to show from the end of the logs (Default: all)"
    echo "  --follow               Follow log output in real-time"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --level)    LOG_LEVEL=$(echo "$2" | tr '[:lower:]' '[:upper:]'); shift 2 ;;
        --file)     COMPOSE_FILE="$2"; shift 2 ;;
        --tail)     TAIL_LINES="$2"; shift 2 ;;
        --follow)   FOLLOW_MODE="true"; shift 1 ;;
        -h|--help)  usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo -e "${RED}ERROR: Compose file '$COMPOSE_FILE' does not exist.${NC}"
    exit 1
fi

COMPOSE_FILENAME=$(basename "$COMPOSE_FILE")
COMPOSE_DIR=$(cd "$(dirname "$COMPOSE_FILE")" && pwd)
ORIGINAL_DIR=$(pwd)

COMPOSE_ARGS=("-f" "$COMPOSE_FILENAME" "logs" "--tail" "$TAIL_LINES" "--no-color=true")
if [[ "$FOLLOW_MODE" == "true" ]]; then
    COMPOSE_ARGS+=("--follow")
fi

echo -e "${CYAN}=====================================================================${NC}"
echo -e "${CYAN}RUNNING DOCKER COMPOSE LOG LEVEL FILTER (${LOG_LEVEL})${NC}"
echo -e "${CYAN}=====================================================================${NC}"
echo -e "${BLUE}Target Directory    : ${COMPOSE_DIR}${NC}"
echo -e "${BLUE}Target Compose File : ${COMPOSE_FILENAME}${NC}"
echo -e "${BLUE}Lines limit         : ${TAIL_LINES}${NC}"
echo -e "${BLUE}Real-time Follow    : ${FOLLOW_MODE}${NC}"
echo -e "${CYAN}---------------------------------------------------------------------${NC}"

echo -e "${YELLOW}Switching context to compose directory and checking stack...${NC}"

cd "$COMPOSE_DIR"

if ! docker compose -f "$COMPOSE_FILENAME" config &>/dev/null && ! docker-compose -f "$COMPOSE_FILENAME" config &>/dev/null; then
    echo -e "${YELLOW}WARNING: Docker Compose config check skipped. Trying to read logs anyway...${NC}\n"
else
    echo -e "${GREEN}Docker compose context verified.${NC}\n"
fi

echo -e "${CYAN}Streaming and sorting logs for level [${LOG_LEVEL}]...${NC}"
echo -e "${CYAN}---------------------------------------------------------------------${NC}"

process_logs() {
    grep --color=never -i -E "(\[|[^a-zA-Z]|^)(${LOG_LEVEL})(\]|[^a-zA-Z]|$)|level=${LOG_LEVEL}" | awk -v nc="$NC" '
    {
        gsub(/\033\[[0-9;]*m/, "")
        line = $0
        c_name = "unknown"

        if (line ~ /^[a-zA-Z0-9_.-]+ *\|/) {
            split(line, parts, "|")
            c_name = parts[1]
            gsub(/ /, "", c_name)
            sub(/^[a-zA-Z0-9_.-]+ *\| */, "", line)
        }
        print c_name ":::" line
    }' | sort -t':' -k1,1 -s | awk -F':::' '
    BEGIN {
        current_container = ""
        colors[0] = 33;   # Yellow
        colors[1] = 38;   # Aqua
        colors[2] = 41;   # Light Blue
        colors[3] = 44;   # Light Green
        colors[4] = 45;   # Turquoise
        colors[5] = 75;   # Sky Blue
        colors[6] = 81;   # Bright Cyan
        colors[7] = 112;  # Lime
        colors[8] = 121;  # Mint
        colors[9] = 135;  # Light Purple
        colors[10] = 171; # Magenta
        colors[11] = 203; # Coral
        colors[12] = 208; # Orange
        colors[13] = 214; # Gold
        colors[14] = 220; # Bright Yellow
    }
    {
        container = $1
        log_content = $2
        if (container != current_container) {
            if (current_container != "") {
                print ""
            }
            current_container = container

            hash = 0
            for (i = 1; i <= length(current_container); i++) {
                hash = (hash * 31 + index("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-", substr(current_container, i, 1))) % 2147483647
            }
            if (hash < 0) hash = -hash
            c_code = "\033[38;5;" colors[hash % 15] "m"

            print c_code "====================================================================="
            print " CONTAINER: " current_container
            print "=====================================================================\033[0m"
        }
        print log_content
    }'
}

if command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
    docker-compose "${COMPOSE_ARGS[@]}" 2>&1 | process_logs || true
else
    docker compose "${COMPOSE_ARGS[@]}" 2>&1 | process_logs || true
fi

cd "$ORIGINAL_DIR"

echo -e "${CYAN}---------------------------------------------------------------------${NC}"
echo -e "${GREEN}Log filtering execution completed.${NC}"
echo -e "${CYAN}=====================================================================${NC}"
exit 0