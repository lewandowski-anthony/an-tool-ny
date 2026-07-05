# an-tool-ny

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/lewandowski-anthony/an-tool-ny/graphs/commit-activity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **an-tool-ny** /ɑ̃.tul.ni/ (noun): Anthony Lewandowski's daily toolbox. Contains everything needed to survive the workday, automate repetitive tasks, and avoid typing the exact same commands 50 times a day.

Welcome to my daily toolbox. This repo brings together the scripts, configs, templates, and small utilities I use to save time and keep repetitive work out of the way.

---

## What's Inside

The repository is organized to make tools easy to find:

* `scripts/`: Automation scripts (Bash, Python, PowerShell, etc.).
* `config/`: Configuration files, custom aliases, and dotfiles.
* `templates/`: Reusable file templates for daily work.
* `utils/`: Miscellaneous helper tools.

---

## Available Tools

Each utility is designed to work standalone or via the provided shortcuts in the configuration file.

### Database

| Tool | Alias | Description |
|---|---|---|
| [`pg-data-generator.sh`](scripts/database/data-generator/postgres/README.md) | `pg-gen` | Introspects a PostgreSQL schema and pushes random, type-safe data while respecting FK order and constraints. Supports `--rows` for bulk generation. |
| [`db-schema-extractor.sh`](scripts/database/schema-extractor/README.md) | `db-extract` | Extracts a database schema into a portable, readable output. Supports multiple database engines. |

### Kubernetes / Ops

| Tool | Alias | Description |
|---|---|---|
| [`k8s-namespace-analyzer.sh`](scripts/ops/k8s/k8s-analyzer/README.md) | `k8s-ns-analyze` | Full audit of a namespace: anomalies, pods, resource usage, events, networking, secrets, Flux CD state, and workloads. |
| [`k8s-port-forward-manager.sh`](scripts/ops/k8s/k8s-port-forwarder/README.md) | `k8s-pf` | Interactive port-forward manager: pick a deployment, free the local port, and forward it as a resilient background process. |
| [`k8s-secret-extractor.sh`](scripts/ops/k8s/k8s-secret-extractor/README.md) | `k8s-secret` | Reconstructs a deployment's full `.env` (inline, `envFrom`, and `valueFrom` refs) with decoded secrets. |
| [`k8s-fast-exec.sh`](scripts/ops/k8s/k8s-fast-exec/README.md) | `k8s-exec` | Opens an instant interactive shell in a pod (`bash` with `sh` fallback), via menu or name/regex. |
| [`k8s-image-tags.sh`](scripts/ops/k8s/k8s-image-tags/README.md) | `k8s-images` | Prints an aligned table of running container images, split into repository / image / tag columns. |
| [`k8s-cluster-curl.sh`](scripts/ops/k8s/k8s-cluster-curl/README.md) | `k8s-curl` | Spawns a disposable pod to probe a target from inside the cluster (HTTP `curl` or raw TCP `nc`). |
| [`k8s-httproute-mapper.sh`](scripts/ops/k8s/k8s-httproute-mapper/README.md) | `k8s-routes` | Builds a routing matrix of Gateway API HTTPRoutes: gateways, hostnames, paths, and backend services. |
| [`k8s-pod-cleaner.sh`](scripts/ops/k8s/k8s-pod-cleaner/README.md) | `k8s-pod-clean` | Force-deletes dead pods (`Evicted`, `Completed`, `Error`, `OOMKilled`) in a namespace. |
| [`k8s-pod-kafka-test.sh`](scripts/ops/k8s/k8s-pod-kafka-test/README.md) | `k8s-kafka-test` | Two-stage Kafka diagnostic from a pod: TCP reachability then `kcat` broker metadata / topic discovery. |
| [`k8s-smart-restart.sh`](scripts/ops/k8s/k8s-smart-restart/README.md) | `k8s-restart` | Interactive zero-downtime rollout restart of a deployment, with live rollout status monitoring. |
| `port-killer.sh` | `port-kill` | Frees a local port by identifying and terminating the occupying process (Docker-aware). Usage: `port-killer.sh <port>`. |

### Development & Analysis

| Tool | Alias | Description |
|---|---|---|
| [`app-ressources-analyze.sh`](scripts/dev/resources/README.md) | `app-analyze` | Analyzes CPU/memory resource usage of one or more Kubernetes pods matched by name/regex. |

### Docker Automation

| Tool | Alias | Description |
|---|---|---|
| `docker-clean-containers.sh` | `docker-clean` | Cleans the local Docker environment by stopping/removing all containers, volumes, and non-default networks. |
| `docker-scan-component.sh` | `docker-scan` | Scans Dockerfiles/images for vulnerabilities using Trivy and writes a consolidated report. |

### Testing & IAM

| Tool | Alias | Description |
|---|---|---|
| `generate_k6_from_swagger.sh` | `k6-gen` | Generates a functional k6 load testing script directly from a provided Swagger / OpenAPI specification file. |
| `jwt-decoder.sh` | `jwt-decode` | Decodes and pretty-prints the header and payload sections of a JSON Web Token (JWT). Usage: `jwt-decoder.sh <jwt_token>`. |

### Git DevOps

| Tool | Alias | Description |
|---|---|---|
| `git-backup-unpushed.sh` | `git-backup-wip` | Scans directories to back up unpushed work, local WIP stashes, or uncommitted modifications. |
| `git-purge-branches.sh` | `git-purge` | Fetches updates, prunes remote tracking branches, and deletes local branches already merged into the main branch. |

---

## Swiss Army Knife Aliases

The repository includes a comprehensive set of daily configuration shortcuts managed via `config/ops/.bash_aliases`.

### Native Stack Shorthands

#### Maven & Gradle
* `mci`: `mvn clean install`
* `mcist`: `mvn clean install -DskipTests`
* `mt`: `mvn test`
* `mcv`: `mvn clean verify`
* `mboot`: `mvn spring-boot:run`
* `mboot-debug`: Starts Spring Boot with a JVM debugger attached to port `5005` (`suspend=n`).
* `gcb`: `./gradlew clean build`
* `gcbst`: `./gradlew clean build -x test`
* `gboot`: `./gradlew bootRun`

#### Docker Engine
* `dps`: Table-formatted lifecycle overview displaying container names, operational status, and active ports.
* `dlo`: Tails the last 100 log frames dynamically (`docker logs -f --tail 100`).
* `dup` / `ddown`: Fast background stack initialization or complete teardown including volumes (`-v`).
* `dnuke`: Emergency hard stop and removal execution across all local active containers.

#### Git Operations
* `gs`: `git status`
* `gaa`: `git add .`
* `gc`: `git commit -m`
* `gpush` / `gpull`: Automated context pushing or pulling using the active tracking branch name dynamically.
* `gl`: Compact graphical overview displaying the top 10 trailing history commits.
* `git-clean-branches`: Bulk removes locally stored branches that have tracking tags marked as `[gone]` on upstream.

#### Navigation & System Utilities
* `c`: `clear`
* `..` / `...`: Fast directory traversal (`cd ..` and `cd ../..`).
* `myip`: Performs an external curl lookup to display public IP configuration instantly.

---

## Detailed Tool Invocation Guide

### 1. Database Utilities

#### Database Schema Extractor
Exports structural metadata (DDL, indexes, collection definitions) without data tracking to files in the `results/` directory.
* **Command Options**:
    * `--type`: Engine target (`mysql`, `postgres`, `oracle`, or `mongo`)
    * `--host`: Server address
    * `--port`: Target port connection
    * `--user`: Connection username
    * `--pass`: Connection password
    * `--name`: Target database name or Oracle SID
* **Direct Execution Examples**:
  ```bash
  # Oracle Schema Extraction
  ./scripts/database/db-schema-extractor.sh --type oracle --host oracle-dev.company.internal --port 1521 --user system --pass MySecureOraclePass --name ORCL

  # MongoDB Collection Mapping
  ./scripts/database/db-schema-extractor.sh --type mongo --host localhost --port 27017 --user admin --pass secretMongoPass --name smartsupply
  ```
* **Alias Usage**:
  ```bash
  db-extract --type postgres --host localhost --port 5432 --user postgres --pass secret --name app_db
  ```

#### PostgreSQL Random Data Generator
Analyzes a live PostgreSQL database and creates a ready-to-execute script containing type-compliant, dependency-aware mock data.
* **Command Options**:
    * `--host`: Server address
    * `--port`: Connection port
    * `--user`: Connection username
    * `--pass`: Connection password
    * `--name`: Database name
    * `--schema`: Specific target schema (defaults to `public`)
    * `--rows`: Maximum mock data row generation target count per table (defaults to `1`)
* **Direct Execution Examples**:
  ```bash
  # Single row verification run
  ./scripts/database/pg-data-generator.sh --host localhost --port 5432 --user postgres --pass MySecurePass --name smartsupply --schema smart_supply

  # Bulk mock data creation (100 rows per table)
  ./scripts/database/pg-data-generator.sh --host localhost --port 5432 --user postgres --pass MySecurePass --name smartsupply --schema smart_supply --rows 100
  ```
* **Alias Usage**:
  ```bash
  pg-gen --host 127.0.0.1 --port 5432 --user context_user --pass secret --name development_db --rows 50
  ```

### 2. Local Networking Utilities

#### Port Killer
Identifies and forcefully terminates processes blocking a specified local TCP port. Cleans Docker containers automatically if they hold the active network binding.
* **Direct Call**:
  ```bash
  ./scripts/ops/local/port-killer.sh 8080
  ```
* **Alias Usage**:
  ```bash
  port-kill 5005
  ```

### 3. Testing Framework Automation

#### OpenAPI K6 Generator
Converts functional Swagger specs into standalone modular k6 typescript execution projects.
* **Direct Call**:
  ```bash
  ./scripts/testing/generate-k6-from-swagger.sh --swagger [https://api.example.com/v3/api-docs](https://api.example.com/v3/api-docs) --output ./load-tests
  ```
* **Alias Usage**:
  ```bash
  k6-gen --swagger ./swagger-spec.json
  ```

### 4. Kubernetes Clusters & Workload Management

#### Namespace Analyzer
Compiles a complete health audit report and logs output structures inside `scripts/ops/k8s/k8s-analyzer/results/`.
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-namespace-analyzer.sh --namespace staging --context production-cluster
  ```
* **Alias Usage**:
  ```bash
  k8s-ns-analyze -n internal-tools
  ```

#### Secret & Environment Extractor
Decodes configuration files and values back into portable `.env` formats matching active workload targets.
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-secret-extractor.sh --namespace default
  ```
* **Alias Usage**:
  ```bash
  k8s-secret
  ```

#### Cluster Internal Network Tester
Triggers short-lived pods to audit internal connectivity channels (HTTP `curl` or raw TCP `nc` handshakes).
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-cluster-curl.sh -n core -t [http://auth-service.core.svc.cluster.local:8080/health](http://auth-service.core.svc.cluster.local:8080/health)
  ```
* **Alias Usage**:
  ```bash
  k8s-curl --target external-db.net:5432
  ```

#### Fast Shell Executive
Provides rapid terminal connection interfaces targetting pods using name matches or regular expression strings.
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-fast-exec.sh --pod payment-gateway-v1
  ```
* **Alias Usage**:
  ```bash
  k8s-exec -p api-worker
  ```

#### Zero-Downtime Rollout Restarter
Launches live rolling container replacement executions step-by-step using interactive menus.
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-smart-restart.sh --namespace routing
  ```
* **Alias Usage**:
  ```bash
  k8s-restart
  ```

#### Namespace Cleaner
Wipes error, evicted, or terminated workloads out of selected namespaces instantly.
* **Direct Call**:
  ```bash
  ./scripts/ops/k8s/k8s-pod-cleaner.sh --namespace testing
  ```
* **Alias Usage**:
  ```bash
  k8s-pod-clean
  ```

---

## Setup & Usage

### 1. Clone the Repository
Clone the repository to your environment. By default, the custom environment configurations assume installation into your user home directory.

```bash
git clone [https://github.com/lewandowski-anthony/an-tool-ny.git](https://github.com/lewandowski-anthony/an-tool-ny.git) $HOME/an-tool-ny
cd $HOME/an-tool-ny
```

### 2. Inject Aliases into Your Shell Configuration
To use the alias suite, append a link reference inside your local runtime initialization runcom file (`.bashrc` or `.zshrc`).

Open your configuration file:
```bash
nano $HOME/.bashrc
# or nano $HOME/.zshrc
```

Add the following sourcing snippet near the bottom of the file:
```bash
# Load an-tool-ny Swiss Army Knife Engine
if [ -f "$HOME/an-tool-ny/config/ops/.bash_aliases" ]; then
    source "$HOME/an-tool-ny/config/ops/.bash_aliases"
fi
```

### 3. Apply Configuration Changes
Reload your shell context directly from the terminal or use the built-in repository automation:
```bash
an-tool-ny-reload
```

---

## Project Philosophy

* If you have to do it more than twice, automate it.
* If the script is ugly but it works, it belongs here.
* Always test locally before running a tool that could break production (ideally).

---

## License

This project is licensed under the MIT License. Feel free to copy what helps and adapt it to your own workflow.

Crafted with coffee and a healthy dose of laziness by Anthony Lewandowski.