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

TITLE=$(echo "$CLEAN_JSON" | jq -r '.info.title // "OpenAPI Collection"')

cat <<EOF > "$OUTPUT_DIR/bruno.json"
{
  "version": "1",
  "name": "$TITLE",
  "type": "collection"
}
EOF

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
      query_params: ([.parameters[]? | select(.in == "query") | .name])
    }
  ] | group_by(.tag) | map(to_entries | map(.value + {seq: (.key + 1)})) | flatten[]
')

while read -r row; do
    if [ -z "$row" ]; then continue; fi

    PATH_URL=$(echo "$row" | jq -r '.path')
    METHOD=$(echo "$row" | jq -r '.method | ascii_downcase')
    TAG=$(echo "$row" | jq -r '.tag')
    NAME=$(echo "$row" | jq -r '.name')
    HAS_BODY=$(echo "$row" | jq -r '.has_body')
    SEQ=$(echo "$row" | jq -r '.seq')

    TAG_FOLDER=$(echo "$TAG" | sed 's/[^a-zA-Z0-9_-]/_/g')
    FILENAME=$(echo "$NAME" | sed 's/[^a-zA-Z0-9_-]/_/g').bru

    FOLDER_PATH="$OUTPUT_DIR/$TAG_FOLDER"
    mkdir -p "$FOLDER_PATH"

    BRUNO_PATH=$(echo "$PATH_URL" | sed -E 's/\{([^}]+)\}/:\1/g')

    BODY_TYPE="none"
    if [ "$HAS_BODY" = "true" ] && [[ "$METHOD" =~ ^(post|put|patch)$ ]]; then
        BODY_TYPE="json"
    fi

    BRU_FILE="$FOLDER_PATH/$FILENAME"

    cat <<EOF > "$BRU_FILE"
meta {
  name: $NAME
  type: http
  seq: $SEQ
}

$METHOD {
  url: {{baseUrl}}$BRUNO_PATH
  body: $BODY_TYPE
  auth: none
}

EOF

    QUERY_PARAMS=$(echo "$row" | jq -r '.query_params[]')
    if [ -n "$QUERY_PARAMS" ]; then
        echo "params:query {" >> "$BRU_FILE"
        while read -r param; do
            if [ -n "$param" ]; then
                echo "  $param: " >> "$BRU_FILE"
            fi
        done <<< "$QUERY_PARAMS"
        echo "}" >> "$BRU_FILE"
        echo "" >> "$BRU_FILE"
    fi

    if [ "$BODY_TYPE" = "json" ]; then
        cat <<EOF >> "$BRU_FILE"
body:json {

}
EOF
    fi

done <<< "$ENDPOINTS"

echo "Generation completed successfully!"