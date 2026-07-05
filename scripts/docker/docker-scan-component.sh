#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
OUTPUT_DIR=""
DEFAULT_VERSION="1.0.0"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        *) TARGET="$1"; shift ;;
    esac
done

OUTPUT_DIR=${OUTPUT_DIR:-"${SCRIPT_DIR}/results"}
RESULT_FILE="${OUTPUT_DIR}/docker_scan_results.txt"

mkdir -p "${OUTPUT_DIR}"
rm -f "$RESULT_FILE"

scan_directory() {
    local dir="$1"

    if [ -f "${dir}Dockerfile" ]; then
        local image_name=$(basename "$dir")
        local version=$DEFAULT_VERSION

        if [ -f "${dir}pom.xml" ]; then
            local maven_name=$(grep -m 1 "<artifactId>" "${dir}pom.xml" | sed -E 's/.*<artifactId>(.*)<\/artifactId>.*/\1/')
            local maven_version=$(grep -m 1 "<version>" "${dir}pom.xml" | sed -E 's/.*<version>(.*)<\/version>.*/\1/')
            [ -n "$maven_name" ] && image_name="$maven_name"
            [ -n "$maven_version" ] && version="$maven_version"
        fi

        local full_image_name="${image_name}:${version}"

        echo "========================================================================" >> "$RESULT_FILE"
        echo " ANALYZING IMAGE : $full_image_name" >> "$RESULT_FILE"
        echo "========================================================================" >> "$RESULT_FILE"

        echo "Building Docker image for $full_image_name..."

        BUILD_LOG=$(mktemp)
        docker build -t "$full_image_name" "$dir" >"$BUILD_LOG" 2>&1
        local build_status=$?

        if [ $build_status -ne 0 ]; then
            echo "[ERROR] Cannot build docker image : $full_image_name" >> "$RESULT_FILE"
            echo "------------------------------------------------------------------------" >> "$RESULT_FILE"
            echo "BUILD FAILED for $full_image_name! Here is the log:"
            echo "----------------------------------------------------"
            cat "$BUILD_LOG"
            echo "----------------------------------------------------"
            rm -f "$BUILD_LOG"
            return
        fi
        rm -f "$BUILD_LOG"

        echo "Scanning Docker image $full_image_name with local Trivy..."

        trivy image --insecure "$full_image_name" >> "$RESULT_FILE" 2>&1 || true

        echo "[SUCCESS] Scan completed for $full_image_name" >> "$RESULT_FILE"
        echo "------------------------------------------------------------------------" >> "$RESULT_FILE"
        echo "" >> "$RESULT_FILE"
    fi
}

if [ -n "$TARGET" ]; then
    if [ "$(basename "$TARGET")" = "Dockerfile" ] && [ -f "$TARGET" ]; then
        TARGET_DIR="$(dirname "$TARGET")/"
    elif [ -d "$TARGET" ]; then
        TARGET_DIR="${TARGET%/}/"
    else
        echo "ERROR: '$TARGET' is not a valid directory or Dockerfile."
        exit 1
    fi

    echo "Target identified. Starting single scan..."
    scan_directory "$TARGET_DIR"
else
    PARENT_DIR="../"
    echo "No parameter provided. Scanning all neighbor directories..."
    for dir in "$PARENT_DIR"*/; do
        scan_directory "$dir"
    done
fi

echo "Docker scans completed. Results available in: $RESULT_FILE"