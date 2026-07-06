# Docker DevSecOps Utilities

This repository contains a collection of automation scripts designed to clean up your local Docker ecosystem, filter container logs by log levels, and perform automated security vulnerability scanning on your Dockerfiles using **Aqua Security Trivy**.

---

## 📋 Table of Contents
1. [Prerequisites](#-prerequisites)
2. [Script 1: Docker Environment Nuke (`clean-docker.sh`)](#script-1-docker-environment-nuke-clean-dockersh)
3. [Script 2: Automated Build & Trivy Scanner (`scan-docker.sh`)](#script-2-automated-build--trivy-scanner-scan-dockersh)
4. [Script 3: Docker Compose Log Filter (`filter-logs.sh`)](#script-3-docker-compose-log-filter-filter-logssh)
5. [Security & Output Results](#-security--output-results)

---

## 🛠 Prerequisites

The cleanup and log filtering scripts run natively with standard Docker installations. However, the scanning script requires **Trivy** to be installed on your host system.

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

This script forcefully sweeps your Docker daemon environment. It is ideal for reclaiming disk space or resetting stuck environments. It systematically removes all running and stopped containers, all volumes, and all custom user networks (safeguarding core drivers like `bridge`, `host`, and `none`).

### Usage
```bash
chmod +x clean-docker.sh
./clean-docker.sh
```

---

## Script 2: Automated Build & Trivy Scanner (`scan-docker.sh`)

This DevSecOps utility targets local directories to automatically compile Docker images and run local container vulnerability scans.

### Key Features
* **Smart Naming Context:** Automatically parses `pom.xml` (Maven) if present to extract the application's exact `<artifactId>` and `<version>` tag for standard image naming configurations.
* **Enterprise-Ready Validation:** Employs an `--insecure` flag to bypass corporate proxy SSL decryption issues while updating the Trivy vulnerability database.
* **Target Flexibility:** Scans a specific custom target `Dockerfile`, an explicitly targeted folder directory, or iterates dynamically through all adjacent neighbor directories (`../`) looking for build contexts.

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

## Script 3: Docker Compose Log Filter (`filter-logs.sh`)

This utility streams logs from a Docker Compose stack and applies targeted structural filtering based on severity level. It matches traditional bracket formats like `[ERROR]` or explicit assignments like `level=ERROR`, then groups and prints the output separated by individual containers with color mapping.

### Key Features
* **Multi-Format Parsing:** Detects patterns like `[ERROR]`, `ERROR`, or `level=ERROR` seamlessly.
* **Deterministic Color Layout:** Automatically hashes container names to consistently map them to one of 15 system ANSI colors for clear readability.
* **Flexible Execution Flags:** Supports custom compose file locations, log history thresholds via tail configuration, and streaming real-time tracking modes.

### Usage

1. **Run with Defaults (Filters `ERROR` level on default `docker-compose.yml` file):**
   ```bash
   chmod +x filter-logs.sh
   ./filter-logs.sh
   ```

2. **Filter Specific Log Levels (e.g., `WARN` or `DEBUG`):**
   ```bash
   ./filter-logs.sh --level WARN
   ```

3. **Specify a Custom Compose File Target with Line Limits:**
   ```bash
   ./filter-logs.sh --file /path/to/docker-compose.prod.yml --tail 100
   ```

4. **Stream Logs Live with Real-Time Filtering:**
   ```bash
   ./filter-logs.sh --level ERROR --follow
   ```

---

## 📊 Security & Output Results

Every scanning evaluation aggregates its analytics pipeline directly inside your active context directory layout:

```text
📁 current-directory/
└── 📁 results/
    └── 📄 docker_scan_results.txt  <-- Comprehensive Vulnerability Reports Here
```

The output file details Vulnerability IDs (CVEs), Severity rankings (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`), Package details, and recommended remediation/fixed versions. If a container fails to compile at runtime, the standard build log gets dumped cleanly inside your standard output stream for structural debugging.