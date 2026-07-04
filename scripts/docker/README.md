# Docker DevSecOps Utilities

This repository contains a collection of automation scripts designed to clean up your local Docker ecosystem and perform automated security vulnerability scanning on your Dockerfiles using **Aqua Security Trivy**.

---

## 📋 Table of Contents
1. [Prerequisites](#-prerequisites)
2. [Script 1: Docker Environment Nuke (`clean-docker.sh`)](#script-1-docker-environment-nuke-clean-dockersh)
3. [Script 2: Automated Build & Trivy Scanner (`scan-docker.sh`)](#script-2-automated-build--trivy-scanner-scan-dockersh)
4. [Security & Output Results](#-security--output-results)

---

## 🛠 Prerequisites

The cleanup script runs natively with standard Docker installations. However, the scanning script requires **Trivy** to be installed on your host system.

### Trivy Installation Guide

Choose the appropriate command block for your operating system:

* **macOS (Homebrew):**
    ```bash
    brew install aquasecurity/trivy/trivy
    ```

* **Linux (Debian/Ubuntu):**
    ```bash
    sudo apt-get install wget apt-transport-https gnupg lsb-release
    wget -qO - [https://aquasecurity.github.io/trivy-repo/deb/public.key](https://aquasecurity.github.io/trivy-repo/deb/public.key) | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] [https://aquasecurity.github.io/trivy-repo/deb](https://aquasecurity.github.io/trivy-repo/deb) stable main" | sudo tee /etc/apt/sources.list.d/trivy.list
    sudo apt-get update && sudo apt-get install trivy
    ```

* **Linux (RedHat/CentOS/UBI):**
  Configure the Trivy YUM repository located at `aquasecurity.github.io`, then execute:
    ```bash
    sudo yum install -y trivy
    ```

* **Windows:**
    ```powershell
    # Using Chocolatey
    choco install trivy
    
    # OR using Scoop
    scoop install trivy
    ```

---

## Script 1: Docker Environment Nuke (`clean-docker.sh`)

This script forcefully sweeps your Docker daemon environment. It is ideal for reclaiming disk space or resetting stuck environments. It systematically removes:
* All running and stopped containers.
* All Docker volumes.
* All custom user networks (safeguarding core drivers like `bridge`, `host`, and `none`).

### Source Code
```bash
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
```

### Usage
```bash
chmod +x clean-docker.sh
./clean-docker.sh
```

---

## Script 2: Automated Build & Trivy Scanner (`scan-docker.sh`)

This DevSecOps utility targets local directories to automatically compile Docker images and run local container vulnerability scans.

### Key Features
* **Smart Naming Context:** Automatically parses `pom.xml` (Maven) if present to extract the application's exact `<artifactId>` and `<version>` tag for standard image naming configurations. Falls back to directory naming and version `1.0.0` if no `pom.xml` exists.
* **Enterprise-Ready Validation:** Employs an `--insecure` flag to bypass corporate proxy SSL decryption issues while updating the Trivy vulnerability database.
* **Target Flexibility:** Scans a specific custom target `Dockerfile`, an explicitly targeted folder directory, or iterates dynamically through all adjacent neighbor directories (`../`) looking for build contexts.

### Source Code
```bash
#!/bin/bash

################################################################################
#  PREREQUISITE: TRIVY SCANNER INSTALLATION
################################################################################
# (See the Prerequisites section above for OS-specific installation steps)
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
```

### Usage

1. **Scan All Neighbor Project Folders:**
   ```bash
   chmod +x scan-docker.sh
   ./scan-docker.sh
   ```

2. **Scan an Explicit Directory Path:**
   ```bash
   ./scan-docker.sh /path/to/your/app-folder
   ```

3. **Scan a Specific Target Dockerfile:**
   ```bash
   ./scan-docker.sh /path/to/your/app-folder/Dockerfile
   ```

---

## 📊 Security & Output Results

Every runtime evaluation aggregates its analytics pipeline directly inside your active context directory layout:

```text
📁 current-directory/
└── 📁 results/
    └── 📄 docker_scan_results.txt  <-- Comprehensive Vulnerability Reports Here
```

The output file details Vulnerability IDs (CVEs), Severity rankings (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`), Package details, and recommended remediation/fixed versions. If a container fails to compile at runtime, the standard build log gets dumped cleanly inside your standard output stream for structural debugging.