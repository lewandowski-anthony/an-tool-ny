#!/bin/bash

################################################################################
#  PREREQUISITE: TRIVY SCANNER INSTALLATION
################################################################################
#
# macOS :
#    brew install aquasecurity/trivy/trivy
#
# Linux (Debian/Ubuntu) :
#    sudo apt-get install wget apt-transport-https gnupg lsb-release
#    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
#    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb stable main" | sudo tee /etc/apt/sources.list.d/trivy.list
#    sudo apt-get update && sudo apt-get install trivy
#
# Linux (RedHat/CentOS/UBI) :
#    Configure the Trivy YUM repository located at aquasecurity.github.io
#    Then execute: sudo yum install -y trivy
#
# Windows (PowerShell) :
#    choco install trivy
#    # OR
#    scoop install trivy
#
################################################################################

set -uo pipefail

RESULT_DIR="results"
RESULT_FILE="${RESULT_DIR}/docker_scan_results.txt"
DEFAULT_VERSION="1.0.0"

mkdir -p "${RESULT_DIR}"
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

        # FIX ENTREPRISE: Utilisation du binaire local + bypass SSL pour la DB de failles
        trivy image --insecure "$full_image_name" >> "$RESULT_FILE" 2>&1 || true

        echo "[SUCCESS] Scan completed for $full_image_name" >> "$RESULT_FILE"
        echo "------------------------------------------------------------------------" >> "$RESULT_FILE"
        echo "" >> "$RESULT_FILE"
    fi
}

if [ "${1:-}" ]; then
    TARGET="$1"
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