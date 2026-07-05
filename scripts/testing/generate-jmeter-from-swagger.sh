#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWAGGER_INPUT=""
OUTPUT_DIR=""

usage() {
    echo "Usage: $0 --swagger <path_to_swagger> [-o|--output <output_directory>]"
    echo "  --swagger      Path to Swagger file (JSON or YAML)"
    echo "  -o, --output   Output directory (Default: 'results' folder in script root)"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --swagger) SWAGGER_INPUT="$2"; shift ;;
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [ -z "$SWAGGER_INPUT" ]; then
    echo "Error: Swagger file (--swagger) is required."
    usage
fi

OUTPUT_DIR=${OUTPUT_DIR:-"$SCRIPT_DIR/results"}
mkdir -p "$OUTPUT_DIR"

if ! command -v npx &> /dev/null; then
    echo "Error: node/npx is required to run this converter."
    exit 1
fi

echo "Converting OpenAPI spec using official @openapitools/openapi-generator-cli..."

npx -y @openapitools/openapi-generator-cli generate \
    -i "$SWAGGER_INPUT" \
    -g jmeter \
    -o "$OUTPUT_DIR"

JMX_FILE=$(find "$OUTPUT_DIR" -name "*.jmx" | head -n 1)

if [ -z "$JMX_FILE" ]; then
    echo "Error: OpenAPI Generator finished, but no .jmx file was detected in $OUTPUT_DIR."
    exit 1
fi

echo "Injecting dynamic performance properties into $(basename "$JMX_FILE")..."

sed -i.bak 's/<stringProp name="ThreadGroup.num_threads">1<\/stringProp>/<stringProp name="ThreadGroup.num_threads">\${__P(vusers,5)}<\/stringProp>/g' "$JMX_FILE"
sed -i.bak 's/<boolProp name="ThreadGroup.scheduler">false<\/boolProp>/<boolProp name="ThreadGroup.scheduler">true<\/boolProp>/g' "$JMX_FILE"
sed -i.bak 's/<stringProp name="ThreadGroup.duration"><\/stringProp>/<stringProp name="ThreadGroup.duration">\${__P(duration,10)}<\/stringProp>/g' "$JMX_FILE"

rm -f "${JMX_FILE}.bak"

echo -e "\nGeneration completed successfully!"
echo " -> JMeter Test Plan saved to: $JMX_FILE"
echo -e "\n💡 How to run your test plan in headless (CLI) mode:"
echo " jmeter -n -t $JMX_FILE -l $OUTPUT_DIR/results.jtl -j $OUTPUT_DIR/jmeter.log -Jvusers=20 -Jduration=60"