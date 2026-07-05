#!/bin/bash

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR=""
OUTPUT_DIR=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo) REPO_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

REPO_DIR=${REPO_DIR:-$(pwd)}
OUTPUT_DIR=${OUTPUT_DIR:-$SCRIPT_DIR/results}

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
else
    echo -e "${RED}ERROR: Workspace directory '$REPO_DIR' not found.${NC}"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo -e "${RED}ERROR: '$(pwd)' is not a valid Git repository.${NC}"
    exit 1
fi

REPO_NAME=$(basename "$(pwd)")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUNDLE_PATH="$OUTPUT_DIR/${REPO_NAME}_unpushed_${TIMESTAMP}.bundle"

UNPUSHED_BRANCHES=""

while read -r branch; do
    clean_branch=$(echo "$branch" | sed 's/^[*[:space:]]*//')
    [ -z "$clean_branch" ] && continue

    if git rev-parse --verify "$clean_branch@{u}" >/dev/null 2>&1; then
        COMMITS=$(git log "$clean_branch@{u}..$clean_branch" --oneline)
        if [ -n "$COMMITS" ]; then
            UNPUSHED_BRANCHES+="$clean_branch "
        fi
    else
        UNPUSHED_BRANCHES+="$clean_branch "
    fi
done < <(git branch --no-color)

if [ -z "$UNPUSHED_BRANCHES" ]; then
    echo -e "${GREEN}Clean setup: No unpushed commits or local-only branches detected for '$REPO_NAME'.${NC}"
    exit 0
fi

mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}ℹFound unpushed/local branches:${NC} $UNPUSHED_BRANCHES"
echo -e "${YELLOW}Packaging into a Git bundle...${NC}"

git bundle create "$BUNDLE_PATH" $UNPUSHED_BRANCHES >/dev/null

echo -e "${GREEN}Backup successful! Your work is safely saved.${NC}"
echo -e "${BLUE}File location:${NC} ${GREEN}$BUNDLE_PATH${NC}"