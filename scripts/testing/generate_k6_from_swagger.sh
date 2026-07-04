#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWAGGER_INPUT=""
OUTPUT_DIR=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --swagger) SWAGGER_INPUT="$2"; shift ;;
        --output) OUTPUT_DIR="$2"; shift ;;
        *) exit 1 ;;
    esac
    shift
done

if [ -z "$SWAGGER_INPUT" ]; then
    exit 1
fi

OUTPUT_DIR=${OUTPUT_DIR:-"$SCRIPT_DIR/results"}

if ! command -v npx &> /dev/null; then
    exit 1
fi

npx -y @grafana/openapi-to-k6 "$SWAGGER_INPUT" "$OUTPUT_DIR" --mode tags

MAIN_FILE="$OUTPUT_DIR/main.ts"
TMP_INIT="$OUTPUT_DIR/tmp_init.txt"
> "$TMP_INIT"

echo "import { sleep } from 'k6';" > "$MAIN_FILE"

find "$OUTPUT_DIR" -name "*.ts" ! -name "main.ts" | while read -r file; do
    rel_path="./$(basename "$file")"
    filename=$(basename "$file" .ts)
    class_name=$(grep -oE "export class [a-zA-Z0-9_]+" "$file" | awk '{print $3}' | head -n 1)

    if [ -n "$class_name" ]; then
        if [ "$class_name" = "Client" ]; then
            echo "import { Client as ${filename}Client } from '$rel_path';" >> "$MAIN_FILE"
            echo "const ${filename,,}Client = new ${filename}Client();" >> "$TMP_INIT"
        else
            echo "import { $class_name } from '$rel_path';" >> "$MAIN_FILE"
            echo "const ${class_name,,} = new ${class_name}();" >> "$TMP_INIT"
        fi
    fi
done

echo "" >> "$MAIN_FILE"
if [ -f "$TMP_INIT" ]; then
    cat "$TMP_INIT" >> "$MAIN_FILE"
    rm "$TMP_INIT"
fi

cat << 'EOF' >> "$MAIN_FILE"

export const options = {
    vus: 5,
    duration: '10s',
    thresholds: {
        http_req_failed: ['rate<0.02'],
        http_req_duration: ['p(95)<1000'],
    },
};

export default function () {
    // Example: userclient.getUsers();
    sleep(1);
}
EOF