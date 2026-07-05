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

echo "Step 1: Converting OpenAPI spec to Gatling simulation project using scala-gatling..."
npx -y @openapitools/openapi-generator-cli generate \
    -i "$SWAGGER_INPUT" \
    -g scala-gatling \
    -o "$OUTPUT_DIR"

# Recherche du fichier de simulation Scala généré
SCALA_FILE=$(find "$OUTPUT_DIR" -name "*Simulation.scala" | head -n 1)

if [ -z "$SCALA_FILE" ]; then
    SCALA_FILE=$(find "$OUTPUT_DIR" -name "*.scala" | head -n 1)
fi

if [ -n "$SCALA_FILE" ]; then
    echo "Step 2: Injecting dynamic performance properties into $(basename "$SCALA_FILE")..."

    # Remplacement de l'injection statique par défaut par la rampe de vusers dynamique
    sed -i.bak 's/atOnceUsers(1)/rampUsers(sys.props.getOrElse("vusers", "5").toInt).during(sys.props.getOrElse("duration", "10").toInt)/g' "$SCALA_FILE"

    rm -f "${SCALA_FILE}.bak"
    echo " -> Gatling Simulation updated successfully: $SCALA_FILE"
else
    echo "Warning: No Scala simulation file detected for property injection."
fi

echo -e "\nGeneration completed successfully!"
echo " -> Project generated into: $OUTPUT_DIR"
echo -e "\n💡 How to run your Gatling test in CLI mode (from the output directory):"
echo " cd $OUTPUT_DIR"
echo " mvn gatling:test -Dvusers=20 -Dduration=60"