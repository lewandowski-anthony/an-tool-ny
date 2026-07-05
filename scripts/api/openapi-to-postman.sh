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
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9_-]/_/g')

echo "$CLEAN_JSON" | jq --arg title "$TITLE" '
  {
    info: {
      name: $title,
      schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    item: [
      .paths | to_entries[] | .key as $path | .value | to_entries[] |
      select(.key | test("^(get|post|put|delete|patch|options|head)$"; "i")) | .key as $method | .value |
      {
        path: $path,
        method: ($method | ascii_upcase),
        tag: (.tags[0] // "default"),
        name: (.summary // .operationId // (($method | ascii_upcase) + " " + $path)),
        has_body: (if .requestBody then true else false end),
        query_params: ([.parameters[]? | select(.in == "query") | .name])
      }
    ] | group_by(.tag) | map({
      name: .[0].tag,
      item: map({
        name: .name,
        request: {
          method: .method,
          header: (if .has_body then [{"key": "Content-Type", "value": "application/json"}] else [] end),
          body: (if .has_body then {mode: "raw", raw: "{\n  \n}"} else null end),
          url: {
            raw: ("{{baseUrl}}" + (.path | gsub("\\{"; ":") | gsub("\\}"; "")) + (if (.query_params | length) > 0 then "?" + (.query_params | map(. + "=") | join("&")) else "" end))
          }
        }
      })
    })
  }
' > "$OUTPUT_DIR/${SAFE_TITLE}.postman_collection.json"

echo "Generation completed successfully!"