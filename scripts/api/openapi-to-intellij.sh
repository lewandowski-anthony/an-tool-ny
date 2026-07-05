#!/bin/bash

set -e

INPUT_FILE=""
OUTPUT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 -i <swagger_file> [-o <output_directory>]"
    echo "  -i, --input    Path to Swagger file (JSON or YAML)"
    echo "  -o, --output   Output directory (Default: 'results' folder in script root)"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_FILE="$2"; shift ;;
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [ -z "$INPUT_FILE" ]; then
    echo "Error: Swagger file (-i/--input) is required."
    usage
fi

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="${SCRIPT_DIR}/results"
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required to run this script."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Processing file: $INPUT_FILE"
echo "Output directory: $OUTPUT_DIR"

CLEAN_JSON=""
if [[ "$INPUT_FILE" == *.yaml ]] || [[ "$INPUT_FILE" == *.yml ]]; then
    if ! command -v yq &> /dev/null; then
        echo "Error: yq is required to parse YAML files."
        exit 1
    fi
    CLEAN_JSON=$(yq -o=json '.' "$INPUT_FILE")
else
    CLEAN_JSON=$(cat "$INPUT_FILE")
fi

ENDPOINTS=$(echo "$CLEAN_JSON" | jq -c '
  [
    .paths | to_entries[] | .key as $path | .value | to_entries[] |
    select(.key | test("^(get|post|put|delete|patch|options|head)$"; "i")) | .key as $method | .value |
    {
      path: $path,
      method: $method,
      tag: (.tags[0] // "default"),
      name: (.summary // .operationId // (($method | ascii_upcase) + " " + $path)),
      has_body: (if .requestBody then true else false end),
      query_string: ([.parameters[]? | select(.in == "query") | .name + "="] | join("&"))
    }
  ] | group_by(.tag) | flatten[]
')

while read -r row; do
    if [ -z "$row" ]; then continue; fi

    PATH_URL=$(echo "$row" | jq -r '.path')
    METHOD=$(echo "$row" | jq -r '.method | ascii_upcase')
    TAG=$(echo "$row" | jq -r '.tag')
    NAME=$(echo "$row" | jq -r '.name')
    HAS_BODY=$(echo "$row" | jq -r '.has_body')
    QUERY_STR=$(echo "$row" | jq -r '.query_string')

    TAG_FOLDER=$(echo "$TAG" | sed 's/[^a-zA-Z0-9_-]/_/g')
    FILENAME=$(echo "$NAME" | sed 's/[^a-zA-Z0-9_-]/_/g').http

    FOLDER_PATH="$OUTPUT_DIR/$TAG_FOLDER"
    mkdir -p "$FOLDER_PATH"

    INTEL_PATH=$(echo "$PATH_URL" | sed -E 's/\{([^}]+)\}/{{\1}}/g')

    if [ -n "$QUERY_STR" ]; then
        FULL_URL="{{baseUrl}}$INTEL_PATH?$QUERY_STR"
    else
        FULL_URL="{{baseUrl}}$INTEL_PATH"
    fi

    HTTP_FILE="$FOLDER_PATH/$FILENAME"

    cat <<EOF > "$HTTP_FILE"
### $NAME
$METHOD $FULL_URL
EOF

    if [ "$HAS_BODY" = "true" ] && [[ "$METHOD" =~ ^(POST|PUT|PATCH)$ ]]; then
        cat <<EOF >> "$HTTP_FILE"
Content-Type: application/json

{

}
EOF
    fi

done <<< "$ENDPOINTS"

echo "Generation completed successfully!"