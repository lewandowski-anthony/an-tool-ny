#!/bin/bash

JWT=$1

if [ -z "$JWT" ]; then
    echo "Error: You must provide a JWT token."
    echo "Usage: $0 <jwt_token>"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install it using: brew install jq"
    exit 1
fi

decode_base64url() {
    local input=$(echo "$1" | tr '_-' '/+')
    local len=${#input}
    local mod=$((len % 4))
    if [ $mod -eq 2 ]; then
        input="${input}=="
    elif [ $mod -eq 3 ]; then
        input="${input}="
    fi
    echo "$input" | openssl base64 -d -A 2>/dev/null
}

HEADER_BASE64=$(echo "$JWT" | cut -d'.' -f1)
PAYLOAD_BASE64=$(echo "$JWT" | cut -d'.' -f2)

if [ -z "$HEADER_BASE64" ] || [ -z "$PAYLOAD_BASE64" ]; then
    echo "Error: Invalid JWT format. A valid JWT must contain at least two dots."
    exit 1
fi

echo "--- HEADER ---"
decode_base64url "$HEADER_BASE64" | jq . 2>/dev/null || echo "Error: Failed to decode or parse Header JSON."

echo -e "\n--- PAYLOAD ---"
decode_base64url "$PAYLOAD_BASE64" | jq . 2>/dev/null || echo "Error: Failed to decode or parse Payload JSON."