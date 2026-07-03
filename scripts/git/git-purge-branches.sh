#!/bin/bash

set -uo pipefail

if [ "${1:-}" ]; then
    if [ -d "$1" ]; then
        cd "$1"
    else
        echo "ERROR: Directory '$1' does not exist."
        exit 1
    fi
fi

echo "Working directory: $(pwd)"

echo "Fetching latest changes and pruning remote tracking branches..."
git fetch --prune >/dev/null 2>&1

MAIN_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
MAIN_BRANCH=${MAIN_BRANCH:-main}

echo "Switching to your main branch ($MAIN_BRANCH)..."
git checkout "$MAIN_BRANCH" >/dev/null 2>&1

echo "Identifying and purging merged local branches..."

# REGEX CORRIGÉE : On nettoie d'abord les espaces/astérisques, puis on filtre les branches interdites
BRANCHES_TO_DELETE=$(git branch --merged | sed 's/^[*[:space:]]*//' | grep -vE "^($MAIN_BRANCH|master|develop)$")

if [ -n "$BRANCHES_TO_DELETE" ]; then
    echo "The following merged branches will be purged:"
    echo "$BRANCHES_TO_DELETE" | sed 's/^/- /'

    echo "$BRANCHES_TO_DELETE" | xargs git branch -d >/dev/null 2>&1
    echo "Purge completed successfully!"
else
    echo "No merged local branches to clean up."
fi