#!/bin/bash

set -uo pipefail

echo "Stopping every container..."
if [ -n "$(docker ps -q)" ]; then
    docker stop $(docker ps -q) >/dev/null 2>&1
fi

echo "Removing every container..."
if [ -n "$(docker ps -aq)" ]; then
    docker rm -f $(docker ps -aq) >/dev/null 2>&1
fi

echo "Removing every volume..."
if [ -n "$(docker volume ls -q)" ]; then
    docker volume rm $(docker volume ls -q) >/dev/null 2>&1
fi

echo "Removing every network..."
NETWORKS=$(docker network ls --format "{{.Name}}" | grep -vE '^(bridge|host|none)$')

if [ -n "$NETWORKS" ]; then
    echo "$NETWORKS" | xargs docker network rm >/dev/null 2>&1
fi

echo "Docker environment cleaned successfully!"